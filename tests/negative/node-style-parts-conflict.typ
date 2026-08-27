#import "/src/lib.typ" as typ
#typ.diagram({
  typ.node(
    0,
    0,
    style: (
      shape: typ.shapes.circle,
      "shape.parts": (typ.shapes.triangle,),
      parts: (typ.shapes.square,),
    ),
  )
})
