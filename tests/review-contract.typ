// Regression/property coverage for the simplification review.
#import "/src/lib.typ" as typ
#import "/src/node.typ": outline-size, draw-outline
#import "/src/diagram.typ": outline-crossing
#import "/src/edge.typ": resolve-edge-path, point-on-segment
#import "/src/geometry.typ": scale-length
#import "/src/utility.typ": node-key
#import "position-helpers.typ": layout
#set text(size: 10pt)

#let close(a, b) = calc.abs(a - b) < 1e-7
#let point-close(a, b) = a.zip(b).all(pair => close(..pair))

// One traversal must give the same boundary from either direction, even
// across stationary segments, concave silhouettes, and mixed curve kinds.
#let shapes = (
  (kind: "circle", radius: 10pt),
  (kind: "ellipse", half-width: 13pt, half-height: 6pt),
  (kind: "rect", half-width: 13pt, half-height: 6pt, radius: 3pt),
  typ.polygon-outline(((-12pt, -8pt), (12pt, -8pt), (4pt, 0pt), (12pt, 8pt), (-12pt, 8pt))),
)
#let paths = (
  typ.edge((0, 0), (0, 0), (0.1, 0), (3, 2), (8, 3), (8, 3)),
  typ.edge((0, 0), typ.quad((1, 3), (4, 0)), typ.cubic((5, -2), (7, 1), (8, 3))),
  typ.edge((0, 0), typ.cubic((0, 0), (3, 2), (3, 2)), (8, 3)),
  typ.edge((0, 0), (0, 0)),
)
#for edge in paths {
  let path = resolve-edge-path(edge.first())
  let starts = (path.start,) + path.segments.slice(0, -1).map(seg => seg.end)
  let reversed = (
    start: path.segments.last().end, straight: path.straight,
    segments: path.segments.enumerate().rev().map(((index, seg)) => (
      kind: seg.kind, ctrl: seg.ctrl.rev(), end: starts.at(index),
    )),
  )
  for outline in shapes {
    for from-end in (false, true) {
      let center = if from-end { path.segments.last().end } else { path.start }
      let crossing = outline-crossing(path, outline, center, 1cm, from-end: from-end)
      let other = outline-crossing(reversed, outline, center, 1cm, from-end: not from-end)
      if crossing == none { assert(other == none) }
      else {
        assert(other != none)
        assert(crossing.segment == path.segments.len() - 1 - other.segment)
        assert(close(crossing.t, 1 - other.t))
        let point = point-on-segment(starts.at(crossing.segment), path.segments.at(crossing.segment), crossing.t)
        let reverse-start = if other.segment == 0 { reversed.start } else { reversed.segments.at(other.segment - 1).end }
        assert(point-close(point, point-on-segment(reverse-start, reversed.segments.at(other.segment), other.t)))
      }
    }
  }
}

// The same bounds routine handles standalone silhouettes and composite bases.
#let measured = (width: 30pt, height: 10pt)
#for shape in shapes + ((kind: "empty"), (kind: "bare")) {
  let composite = (kind: "parts", base: (outline: shape), parts: ())
  assert(outline-size(shape, measured) == outline-size(composite, measured))
}
#let shifted = (kind: "rect", half-width: 5pt, half-height: 4pt, radius: 0pt, label-offset: (8pt, -6pt))
#assert(outline-size(shifted, measured) == (
  left: -7pt, right: 23pt, top: -11pt, bottom: 4pt, width: 30pt, height: 15pt,
))

// Absolute pieces scale once; ratios continue to refer to the resized base.
#for (value, expected) in ((2pt, 6pt), (25%, 25%), (25% + 2pt, 25% + 6pt), (2, 6), (auto, auto)) {
  assert(scale-length(value, 3) == expected)
}
#context {
  // Selective identity buckets are only an accelerator. Distinct extension
  // data, including closures with the same repr, must survive deduplication.
  let extension(amount) = value => value + amount
  let source = typ.node(0, 0, name: "source")
  let a = typ.make-node("custom", typ.offset(typ.ref("source"), 1, 0), extra: extension(1))
  let b = typ.make-node("custom", typ.offset(typ.ref("source"), 1, 0), extra: extension(2))
  assert(node-key(a.first()) == node-key(b.first()))
  assert(layout(source + a + a + b).nodes.len() == 3)
  for shape in shapes.slice(0, 3) {
    let no-label = draw-outline(shape, white, none, [])
    let labelled = draw-outline(shape, white, none, [x])
    assert(measure(no-label) == measure(labelled), message: "labels overlay the native shape without changing its frame")
  }
  // Exercise the shared sizing helper through contextual em and part-local
  // overrides, including both percentage-only and mixed corner radii.
  let node = typ.node(0, 0, style: (
    shape: typ.shapes.rect, min-size: 20pt, radius: 20% + 1pt,
    parts: ((shape: typ.shapes.rect, min-size: 1em, radius: 50% + 0.1em, transform: (1em, -1em)),),
  )).first()
  let prep = typ.node-outline(node, size-factor: 2)
  assert(prep.outline.base.outline.radius == 6pt)
  let part = prep.outline.parts.first()
  assert(part.outline.half-width == 10pt and part.outline.radius == 7pt)
  assert(part.transform == (20pt, -20pt))
}
