// Polygon validation must receive absolute lengths after contextual sizing.
#import "/src/lib.typ" as typ
#set text(size: 10pt)
#typ.diagram(typ.node(0, 0, style: (shape: typ.shapes.diamond, min-size: 1em)))

#context {
  for shape in (
    typ.shapes.diamond, typ.shapes.triangle, typ.shapes.arrow,
    typ.shapes.trapezoid, typ.shapes.hexagon,
    typ.shapes.polygon(((-1, -1), (1, -1), (1, 1), (-1, 1))),
  ) {
    let node = typ.node(0, 0, style: (shape: shape, min-size: 2em, inset: 0.1em)).first()
    let em = typ.node-outline(node, size-factor: 2).outline
    let pt = typ.node-outline(node + (style: node.style + (min-size: 20pt, inset: 1pt)), size-factor: 2).outline
    assert(em == pt)
    for direction in range(0, 360, step: 15) {
      assert(typ.shape-radius(em, direction * 1deg) > 0pt)
    }
    typ.diagram(typ.edge((node,), (2, 1)))
  }
}
