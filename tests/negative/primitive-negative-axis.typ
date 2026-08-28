// Reject this input at the intended validation boundary.
#import "/src/lib.typ" as typ
#let bad(label, pad, style) = (kind: "ellipse", half-width: -1pt, half-height: 2pt)
#typ.diagram(typ.node(0, 0, style: (shape: bad)))
