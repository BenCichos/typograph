// Valid length input: clipping must resolve em before converting to numbers.
#import "/src/lib.typ" as typ
#set text(size: 10pt)
#import "/src/geometry.typ": is-size-length, absolute-length
// Constructors and pure absolute helpers must not require a layout context.
#for value in (0pt, 1pt, 1em, 1em + 2pt, 1em - 2pt, 2pt - 1em) {
  assert(is-size-length(value))
}
#for value in (-1pt, -1em, -1em - 2pt, auto, "1em") {
  assert(not is-size-length(value))
}
#assert(not is-size-length(0pt, positive: true))
#assert(absolute-length(2pt) == 2pt and absolute-length(20% + 2pt) == 20% + 2pt)
#typ.diagram(typ.edge(
  typ.node(0, 0, style: (shape: typ.shapes.circle, min-size: 1em)),
  (2, 0),
))

#let near(a, b) = calc.abs((a - b) / 1pt) < 1e-6
#let styled(style) = typ.node(0, 0, style: style).first()
#for font in (10pt, 20pt) {
  set text(size: font)
  context {
    for zoom in (0.5, 1, 2) {
      let prep = typ.node-outline(styled((
        shape: typ.shapes.rect, min-size: 2em, min-height: 3em,
        inset: (left: 0.2em, right: 1pt, top: 0.3em, bottom: 2pt),
        radius: 10% + 0.1em, stroke: 0.1em + red,
      )), size-factor: zoom)
      assert(near(prep.outline.half-width, font * zoom))
      assert(near(prep.outline.half-height, 1.5 * font * zoom))
      assert(near(prep.outline.radius, 0.2 * font * zoom))
      assert(near(prep.outline.label-offset.at(0), (0.2 * font - 1pt) * zoom / 2))
      assert(near(prep.outline.label-offset.at(1), (0.3 * font - 2pt) * zoom / 2))
      assert(near(stroke(prep.style.stroke).thickness, 0.1 * font * zoom))

      // Parts and marks normalize their own fields, without double-scaling
      // inherited geometry. Unknown custom-builder data remains untouched.
      let custom(label, pad, style) = {
        assert(style.custom-length == 3em)
        typ.shapes.circle(label, pad, style)
      }
      let compound = typ.node-outline(styled((
        shape: custom, min-size: 2em, custom-length: 3em,
        mark: "cross", mark-size: 0.6em, mark-thickness: 0.1em, mark-fill: black,
        "shape.parts": ((
          shape: typ.shapes.rect, min-size: 0.5em, radius: 0.1em,
          transform: (x: 3em, y: -1em), stroke: 0.1em + blue,
        ),),
      )), size-factor: zoom)
      let badge = compound.outline.parts.first()
      assert(badge.transform == (3 * font * zoom, -font * zoom))
      assert(near(badge.outline.half-width, 0.25 * font * zoom))
      assert(near(stroke(badge.stroke).thickness, 0.1 * font * zoom))
      assert(compound.outline.parts.len() == 2)
      assert(compound.outline.parts.last().outline.points.all(p => p.all(v => v.em == 0)))

      let measurement = typ.node-outline(styled((
        shape: typ.shapes.rect, min-size: 2em,
        mark: "measurement", mark-size: 0.8em,
        mark-stroke: 0.1em + black,
        "shape.parts": ((shape: typ.shapes.circle, transform: (2em, -1em)),),
      )), size-factor: zoom)
      assert(measurement.outline.parts.first().transform == (2 * font * zoom, -font * zoom))
      assert(measurement.outline.parts.len() > 1)
    }
    // Mixed-sign components are validated only after their contextual sum
    // is known. Both signs can produce valid positive lengths.
    for amount in (2em - 5pt, 50pt - 1em) {
      let outline = typ.node-outline(styled((shape: typ.shapes.circle, min-size: amount))).outline
      assert(near(outline.radius, amount.to-absolute() / 2))
    }
    let label = typ.node(0, 0, label: [Ag], style: (shape: typ.shapes.bare, font-size: 1.5em)).first()
    let em = typ.node-outline(label).measured
    let pt = typ.node-outline(label + (style: label.style + (font-size: 1.5 * font))).measured
    assert(near(em.width, pt.width) and near(em.height, pt.height))
  }
}

// The public layout path also accepts em-valued margins and mixed zooms.
#typ.diagram(scale: 4em - 5pt, inset: (x: 0.5em, y: 1pt), typ.edge(
  typ.node(0, 0, style: (shape: typ.shapes.circle, min-size: 1em, inset: 0.2em)),
  (2, 0),
))
