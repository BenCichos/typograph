#import "/src/lib.typ" as typ
#set text(size: 10pt)
#typ.diagram(typ.node(0, 0, style: (
  shape: typ.shapes.circle, min-size: 10pt,
  "shape.parts": ((shape: typ.shapes.rect, min-size: 1em - 20pt),),
)))
