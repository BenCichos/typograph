// Stroke bounds must resolve font-relative lengths before min/max arithmetic.
#import "/src/lib.typ" as typ
#set text(size: 10pt)
#typ.diagram(typ.edge((0, 0), (2, 0), stroke: 0.1em + black))

#import "/src/style.typ": absolute-stroke, absolute-edge-style
#context {
  for spec in (0.1em, 0.1em + red, (paint: blue, thickness: 0.1em, cap: "square", join: "round", dash: "dashed", miter-limit: 5)) {
    let before = stroke(spec)
    let after = stroke(absolute-stroke(spec))
    assert(after.thickness == 1pt)
    assert(after.paint == before.paint and after.cap == before.cap)
    assert(after.join == before.join and after.dash == before.dash)
    assert(after.miter-limit == before.miter-limit)
  }
  for unchanged in (none, auto, red, 1pt, (thickness: 1pt)) {
    assert(absolute-stroke(unchanged) == unchanged)
  }
  let relative = absolute-edge-style((label-inset: (x: 10% + 0.1em, y: 0.2em)))
  assert(relative.label-inset == (x: 10% + 1pt, y: 2pt))
  let edge(unit) = typ.edge((0, 0), (1, 1), (2, 0), label: [Ag], highlight: (red, blue), style: (
    stroke: (paint: black, thickness: 0.1 * unit, cap: "square"),
    highlight-width: 0.4 * unit, highlight-offset: 0.1 * unit,
    label-size: 1.2 * unit, label-offset: -0.3 * unit,
    label-inset: (x: 10% + 0.1 * unit, y: 0.2 * unit),
  ))
  for scale in (0.5, 1, 2) {
    assert(measure(typ.diagram(scale: scale, edge(1em))) == measure(typ.diagram(scale: scale, edge(10pt))))
  }
  typ.diagram(edge(1em))
}
