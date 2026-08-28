// Reject this input at the intended validation boundary.
#import "/src/lib.typ" as typ
#typ.gate(0, 0, none, max-legs-per-side: -1)
