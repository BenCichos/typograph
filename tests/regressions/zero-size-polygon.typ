// Neutral defaults must leave a valid, non-degenerate polygon template.
#import "/src/lib.typ" as typ
#typ.diagram(typ.node(0, 0, style: (shape: typ.shapes.diamond)))

#for builder in (
  typ.shapes.diamond, typ.shapes.hexagon, typ.shapes.regular(vertices: 3),
  typ.shapes.regular(vertices: 9), typ.shapes.triangle,
  typ.shapes.triangle("isosceles", ratio: 0.5),
  typ.shapes.triangle("angles", angles: (0deg, 120deg, 240deg)),
  typ.shapes.flat-triangle, typ.shapes.broad-triangle,
  typ.shapes.trapezoid, typ.shapes.arrow,
) {
  for minima in ((0pt, 0pt), (4pt, 0pt), (0pt, 6pt)) {
    for rotation in (0deg, 37deg) {
      let n = typ.node(0, 0, style: (
        shape: builder, min-width: minima.at(0), min-height: minima.at(1),
        rotate: rotation, flip: true,
      ))
      let outline = typ.node-outline(n.first()).outline
      assert(outline.kind == "polygon")
      assert(outline.half-width > 0pt and outline.half-height > 0pt)
      for angle in range(0, 360, step: 30) {
        assert(typ.shape-radius(outline, angle * 1deg) > 0pt)
      }
      typ.diagram(typ.edge(n, (1, 0)))
    }
  }
}

// A safeguard for absent extents, not a minimum forced on explicit sizes.
#let tiny = typ.node(0, 0, style: (shape: typ.shapes.diamond, min-size: 0.1pt)).first()
#assert(typ.node-outline(tiny).outline.half-width == 0.05pt)
// Empty routing points and non-polygon zero-size outlines retain zero size.
#assert(typ.node-outline(typ.node(0, 0).first()).outline.kind == "empty")
#assert(typ.node-outline(typ.node(0, 0, style: (shape: typ.shapes.circle)).first()).outline.radius == 0pt)
