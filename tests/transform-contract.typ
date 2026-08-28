// Affine transforms must agree before and after path construction. These
// tests cover nonzero pivots, mixed curves, nesting, and deferred endpoints.
#import "/src/lib.typ" as typ
#import "/src/edge.typ": resolve-edge-path, point-on-segment
#import "/src/diagram.typ": node-key, resolve-deferred-waypoints

#let close(a, b) = calc.abs(a - b) < 1e-7
#let point-close(a, b) = a.zip(b).all(pair => close(..pair))
#let pivot = (2, -3)
#let transform(p) = {
  let r = typ.rotate-point((p.at(0) - pivot.at(0), p.at(1) - pivot.at(1)), 37deg)
  (pivot.at(0) + 2.5 * r.at(0) + 4, pivot.at(1) + 2.5 * r.at(1) - 1)
}
#let transform-items = typ.group.with(dx: 4, dy: -1, scale: 2.5, rotate: 37deg, pivot: pivot)
#let paths = (
  typ.edge((0, 0), (1, 2), typ.quad((3, 5), (4, -1)), typ.cubic((5, -3), (6, 2), (7, 0))),
  typ.edge((0, 0), typ.smooth((1, 2)), typ.smooth((3, 4)), (5, 0), (6, 1)),
  typ.edge((0, 0), (2, 1), (3, -1), bend: -0.6),
  typ.edge((0, 0), (2, 1), from: (top, 2), to: (left, 0.7)),
)
#for items in paths {
  let before = resolve-edge-path(items.first())
  let after = resolve-edge-path(transform-items(items).first())
  assert(after.segments.len() == before.segments.len())
  assert(after.straight == before.straight)
  let before-start = before.start
  let after-start = after.start
  for (a, b) in before.segments.zip(after.segments) {
    assert(a.kind == b.kind)
    for t in (0, 0.1, 0.5, 0.9, 1) {
      assert(point-close(
        transform(point-on-segment(before-start, a, t)),
        point-on-segment(after-start, b, t),
      ), message: "group commutes with path construction")
    }
    before-start = a.end
    after-start = b.end
  }
}

#let original = typ.node(2, -3, label: [upright], name: "source", style: (rotate: 15deg))
#let moved = transform-items(original).first()
#assert(point-close((moved.x, moved.y), (6, -4)))
#assert(moved.label == original.first().label and moved.style == original.first().style)
#assert(moved.name == "source" and moved.size-scale == 2.5)
#assert(original.first().size-scale == 1 and original.first().x == 2)

// Captured node and clip target must remain equal to the separately emitted
// transformed node, without mutating the original reusable fragment.
#let captured = transform-items(typ.edge(original, (5, 2))).first().waypoints.first()
#assert(captured.node == moved and captured.clip-to == moved)

// place() changes its position only: arbitrary Typst content is not resized
// or rotated, and physical alignment is unchanged.
#let placed = typ.place(1, 2, rect(width: 12pt, height: 6pt), align: right + bottom)
#let placed-after = transform-items(placed).first()
#assert(point-close((placed-after.x, placed-after.y), transform((1, 2))))
#assert(placed-after.body == placed.first().body and placed-after.align == placed.first().align)
#assert(typ.group() == ())
#assert(typ.group(((original,), (placed,))) == original + placed)

// Rotation and reciprocal scaling about the same nonzero pivot are inverses.
#let nested = typ.group(
  rotate: -37deg, scale: 0.4, pivot: pivot,
  typ.group(rotate: 37deg, scale: 2.5, pivot: pivot, paths.first()),
).first()
#let restored = resolve-edge-path(nested)
#let initial = resolve-edge-path(paths.first().first())
#assert(point-close(restored.start, initial.start))
#assert(close(nested.size-scale, 1))
#for (a, b) in restored.segments.zip(initial.segments) {
  assert(point-close(a.end, b.end))
  for (p, q) in a.ctrl.zip(b.ctrl) { assert(point-close(p, q)) }
}

// Absolute controls transform even when their destination is deferred.
// Relative offsets are vectors: they must not receive the translation.
#let relative = typ.edge((1, 2), typ.quad((2, 4), typ.rel(2, -1)), typ.cubic((4, 5), (6, 0), typ.rel(-1, 3)))
#let resolved-before = resolve-deferred-waypoints(relative.first(), (:), (:), 1cm)
#let resolved-after = resolve-deferred-waypoints(transform-items(relative).first(), (:), (:), 1cm)
#for (a, b) in resolved-before.waypoints.zip(resolved-after.waypoints) {
  assert(point-close(transform(a.end), b.end))
  if a.ctrl != none {
    for (p, q) in a.ctrl.zip(b.ctrl) { assert(point-close(transform(p), q)) }
  }
}

// A named ref resolves to the transformed emitted node; group does not rename
// it or create a private name scope.
#let ref-edge = transform-items(typ.edge(typ.ref("source"), typ.rel(1, 0))).first()
#let ref-resolved = resolve-deferred-waypoints(ref-edge, (:), (source: moved), 1cm)
#assert(ref-resolved.waypoints.first().clip-to == moved)
#assert(point-close(ref-resolved.waypoints.first().end, (moved.x, moved.y)))
#assert(point-close(ref-resolved.waypoints.last().end, transform((3, -3))))

// Deferred port rotation composes across nested groups, including controls
// on a cubic segment ending at that port. Circle silhouettes are rotation-
// invariant, so their physical port position transforms exactly.
#let gate = typ.gate(1, 2, none, legs: (left: 2), size: 20pt, style: (shape: typ.shapes.circle))
#let port-edge = typ.edge((0, 0), typ.cubic((1, 3), (2, 3), typ.port(gate, "left", 1)))
#let port-after = typ.group(rotate: 17deg, typ.group(rotate: 20deg, port-edge)).first()
#let after-gate = port-after.waypoints.last().node
#assert(port-after.waypoints.last().defer.node == after-gate)
#assert(port-after.waypoints.last().defer.rotate == 37deg)
#let lookup(n) = ((node-key(n)): ((node: n, outline: typ.node-outline(n).outline),))
#let before = resolve-deferred-waypoints(port-edge.first(), lookup(gate.first()), (:), 1cm, port-spacing: 4pt)
#let after = resolve-deferred-waypoints(port-after, lookup(after-gate), (:), 1cm, port-spacing: 4pt)
#assert(point-close(typ.rotate-point(before.waypoints.last().end, 37deg), after.waypoints.last().end))
#assert(after.waypoints.last().clip-to == none)
