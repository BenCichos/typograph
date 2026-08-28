// A circle advertised as fitted around its label must contain a square label's
// corners. Multiplying the larger dimension by 1.2 is less than sqrt(2).
#import "/src/lib.typ" as typ
#context {
  let n = typ.node(0, 0, label: rect(width: 20pt, height: 20pt), style: (shape: typ.shapes.circle))
  let prep = typ.node-outline(n.first())
  assert(
    prep.outline.radius >= calc.sqrt(200) * 1pt,
    message: "circle does not contain square label",
  )
}

#let near(a, b) = calc.abs((a - b) / 1pt) < 1e-6
#let contains-label(outline, label) = {
  for x in (-label.width / 2, label.width / 2) {
    for y in (-label.height / 2, label.height / 2) {
      let dx = (x + outline.label-offset.at(0)) / 1pt
      let dy = (y + outline.label-offset.at(1)) / 1pt
      assert(calc.sqrt(dx * dx + dy * dy) * 1pt <= outline.radius + 0.000001pt)
    }
  }
}
#for dimensions in ((20pt, 20pt), (24pt, 16pt), (40pt, 4pt), (0pt, 12pt)) {
  for pad in (0pt, 2pt, (left: 7pt, right: 1pt, top: 9pt, bottom: 0pt)) {
    let measured = (width: dimensions.at(0), height: dimensions.at(1))
    let style = typ.resolve-node-style("node", (:), (shape: typ.shapes.circle, inset: pad))
    contains-label(typ.shape-outline(style, [label], measured), measured)
  }
}

#context {
  let n = typ.node(0, 0, label: rect(width: 2em, height: 2em), style: (shape: typ.shapes.circle)).first()
  let normal = typ.node-outline(n)
  let zoomed = typ.node-outline(n, size-factor: 2)
  contains-label(normal.outline, normal.measured)
  contains-label(zoomed.outline, zoomed.measured)
  assert(near(zoomed.outline.radius, normal.outline.radius * 2))
}

// Preserve the previous clearance and explicit minima when already larger.
#let large = typ.resolve-node-style("node", (:), (shape: typ.shapes.circle, min-size: 60pt))
#assert(typ.shape-outline(large, [label], (width: 20pt, height: 20pt)).radius == 30pt)
#let thin = typ.resolve-node-style("node", (:), (shape: typ.shapes.circle))
#assert(typ.shape-outline(thin, [label], (width: 40pt, height: 4pt)).radius == 24pt)
#assert(typ.node-outline(typ.node(0, 0, style: (shape: typ.shapes.circle)).first()).outline.radius == 0pt)
