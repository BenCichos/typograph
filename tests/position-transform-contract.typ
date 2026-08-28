#import "/src/lib.typ" as typ
#import "position-helpers.typ": close, pair-close, layout, named, xy
#let add(a, b) = a.zip(b).map(pair => pair.at(0) + pair.at(1))
#let subtract(a, b) = a.zip(b).map(pair => pair.at(0) - pair.at(1))
#let multiply(p, s) = p.map(v => v * s)
#let forward(p, spec) = add(add(spec.pivot, multiply(typ.rotate-point(subtract(p, spec.pivot), spec.rotate), spec.scale)), (spec.dx, spec.dy))
#let inverse(p, spec) = add(spec.pivot, multiply(typ.rotate-point(subtract(subtract(p, (spec.dx, spec.dy)), spec.pivot), -spec.rotate), 1 / spec.scale))
#let vector(p, spec) = multiply(typ.rotate-point(p, spec.rotate), spec.scale)

#context {
  let g = typ.gate(1, 2, none, size: (36pt, 16pt), legs: (right: 2), name: "g")
  let p = typ.port(g, "right", 1)
  let fragment = {
    typ.box(typ.offset(p, 0.5, -0.2), name: "full")
    typ.node(p.x, -1, name: "x-only")
    typ.node(-2, p.y, name: "y-only")
    typ.place(p, [at port])
    typ.edge(p, typ.rel(1, 0))
  }
  for angle in (0deg, 90deg, 37deg, -125deg) {
    let spec = (dx: 3, dy: -2, scale: 1.6, rotate: angle, pivot: (2, -3))
    let moved = typ.group(..spec, fragment)
    let result = layout(moved)
    let endpoint = result.work.last().waypoints.first().end
    assert(pair-close(xy(named(result, "full")), add(endpoint, vector((0.5, -0.2), spec))))
    assert(pair-close(xy(result.work.first()), endpoint))
    let local-port = inverse(endpoint, spec)
    assert(pair-close(xy(named(result, "x-only")), forward((local-port.at(0), -1), spec)))
    assert(pair-close(xy(named(result, "y-only")), forward((-2, local-port.at(1)), spec)))
    assert(named(result, "g").style == g.first().style, message: "graphics stay upright")
    assert(g.first().size-scale == 1, message: "source fragment is immutable")
    typ.diagram(moved)
  }
  let inner = (dx: -1, dy: 2, scale: 0.7, rotate: 23deg, pivot: (2, 1))
  let outer = (dx: 4, dy: -3, scale: 1.8, rotate: 14deg, pivot: (-1, 2))
  let nested = layout(typ.group(..outer, typ.group(..inner, fragment)))
  let endpoint = nested.work.last().waypoints.first().end
  assert(pair-close(xy(named(nested, "full")), add(endpoint, vector(vector((0.5, -0.2), inner), outer))))
  let original = inverse(inverse(endpoint, outer), inner)
  assert(pair-close(xy(named(nested, "x-only")), forward(forward((original.at(0), -1), inner), outer)))

  // Named references stay global even when the referring fragment moves.
  let named-port = typ.port(typ.ref("outside"), "right")
  let global = layout({
    typ.gate(4, 5, none, name: "outside", size: 20pt)
    typ.group(dx: 10, dy: -3, {
      typ.box(typ.ref("outside"), name: "center")
      typ.node(named-port.x, 2, name: "projected")
      typ.node(typ.offset(named-port, 1, 0), name: "offset")
    })
  })
  assert(xy(named(global, "center")) == (4, 5))
  assert(pair-close(xy(named(global, "projected")), (4 + 10pt / 1cm, -1)))
  assert(pair-close(xy(named(global, "offset")), (5 + 10pt / 1cm, 5)))

  // Relative-node clipping and numeric control points work together for
  // directed, quadratic, cubic, and smoothed paths, including after grouping.
  let end = typ.box(typ.offset(p, 2, 0), name: "curve-end", label: [N])
  let paths = {
    typ.edge(p, end, from: right, to: top)
    typ.edge(p, typ.quad((2, 4), end))
    typ.edge(p, typ.cubic((2, -1), (3, 4), end))
    typ.edge(p, typ.smooth((2, 3)), end)
    typ.edge((p.x, -1), typ.offset(p, 1, -1), clip: false)
  }
  for fragment in (paths, typ.group(..outer, paths)) {
    let resolved = layout(fragment)
    let actual = measure(typ.diagram(fragment, inset: 0pt))
    let expected = measure(typ.diagram(resolved.nodes + resolved.work, inset: 0pt))
    assert(close(actual.width.pt(), expected.width.pt()) and close(actual.height.pt(), expected.height.pt()))
    assert(resolved.work.last().waypoints.all(wp => wp.clip-to == none))
  }

  // Layout/measurement must agree with the corresponding numeric diagram,
  // across label fitting, em dimensions, style layers, zoom and edge spacing.
  for label in (none, [U], [a substantially wider gate label]) {
    for zoom in (0.6, 1, 2) {
      for edge-scale in (0.5, 1, 3) {
        let gate = typ.gate(0, 0, label, name: "source", size: 1em, legs: (right: 3))
        let port = typ.port(gate, "right", 2)
        let follower = typ.box(typ.offset(port, 1, 0), name: "follower", label: [N])
        let items = { typ.edge(port, follower); typ.place(port.x, -1, [caption], align: left + top) }
        let overrides = (gate: (inset: 0.2em, radius: 2pt))
        let result = layout(items, unit: zoom * edge-scale * 1cm, size-factor: zoom,
          port-spacing: 0.6em, overrides: overrides, font-size: 12pt)
        let endpoint = result.work.first().waypoints.first().end
        assert(pair-close(xy(named(result, "follower")), add(endpoint, (1, 0))))
        let settings = (scale: zoom, scale-edges: edge-scale, port-spacing: 0.6em,
          node-styles: overrides, font-size: 12pt, inset: 0pt)
        let actual = measure(typ.diagram(items, ..settings))
        let expected = measure(typ.diagram(result.nodes + result.work, ..settings))
        assert(close(actual.width.pt(), expected.width.pt()) and close(actual.height.pt(), expected.height.pt()))
      }
    }
  }
}
