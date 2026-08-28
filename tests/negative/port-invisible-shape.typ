// Reject this input at the intended validation boundary.
#import "/src/lib.typ" as typ
#let g = typ.gate(0, 0, none, style: (shape: typ.shapes.empty))
#typ.diagram(typ.edge(typ.port(g, "right"), (1, 0)))
