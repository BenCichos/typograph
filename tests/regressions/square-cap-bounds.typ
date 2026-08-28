// At 45 degrees a square cap's tangent and normal projections both contribute
// to its x/y extent. A half-thickness axis outset is insufficient.
#import "/src/lib.typ" as typ
#context {
  let size = measure(typ.diagram(inset: 0pt, baseline: 0pt, typ.edge(
    (0, 0), (1, 1), stroke: (paint: black, thickness: 10pt, cap: "square"),
  )))
  assert(
    size.width >= 1cm + 10pt * calc.sqrt(2) - 0.0001pt,
    message: "square cap exceeds declared bounds",
  )
}

#import "/src/diagram.typ": stroke-outset, edge-visual-radius
#let spec = (paint: black, thickness: 10pt, cap: "square", join: "round")
// Caps matter only for open paths: closed node silhouettes stay unchanged.
#assert(stroke-outset(spec) == 5pt)
#assert(stroke-outset(spec, open: true) == 5pt * calc.sqrt(2))
#assert(stroke-outset(spec, open: true, miter: true) == 5pt * calc.sqrt(2))
#assert(stroke-outset(spec + (join: "miter", miter-limit: 4), open: true, miter: true) == 40pt)
#for cap in ("butt", "round") {
  assert(stroke-outset(spec + (cap: cap), open: true) == 5pt)
}
#for angle in range(0, 360, step: 15) {
  let tangent = (calc.cos(angle * 1deg), calc.sin(angle * 1deg))
  let normal = (-tangent.at(1), tangent.at(0))
  for zoom in (0.5, 1, 2) {
    let radius = edge-visual-radius(typ.edge-defaults + (stroke: spec), (), zoom)
    // Check every corner of the rotated cap square on both ends.
    for along in (-1, 1) {
      for across in (-1, 1) {
        for axis in (0, 1) {
          let corner = (along * tangent.at(axis) + across * normal.at(axis)) * 5pt * zoom
          assert(calc.abs(corner) <= radius + 0.000001pt)
        }
      }
    }
  }
}
