#import "/src/lib.typ" as typ
// These are not interior angles: all vertices would lie in one quadrant.
#typ.diagram(typ.node(0, 0, label: [T], style: (
  shape: typ.shapes.triangle("angles", angles: (30deg, 70deg, 80deg)),
)))
