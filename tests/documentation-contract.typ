// Executable counterparts of constructor docstrings and the guide's new
// fragment-name / font-relative-length examples. This is not a parser for
// all Quarto snippets: signatures and pseudocode remain non-executable.
#import "/src/lib.typ" as typ
#set page(width: auto, height: auto, margin: 8pt)

// diagram.typ and content.typ docstrings: box's label is named, unlike gate's.
#let motif = {
  let a = typ.box(0, 0, label: [A])
  let b = typ.box(0, 1, label: [B])
  typ.edge(a, b)
}
#typ.diagram({
  typ.group(motif)
  typ.group(dx: 2, scale: 0.6, motif)
})

// A group has no separate name scope. Generate distinct names when stamping
// a fragment whose edges use ref(), and emit the named nodes explicitly.
#let named-pair(prefix) = {
  typ.box(0, 0, label: [A], name: prefix + "-a")
  typ.box(1, 0, label: [B], name: prefix + "-b")
  typ.edge(typ.ref(prefix + "-a"), typ.ref(prefix + "-b"))
}
#typ.diagram({
  named-pair("first")
  typ.group(dy: -1, named-pair("second"))
})

// Angles denote vertex positions on a circumcircle, not interior angles.
#typ.diagram(typ.node(0, 0, label: [T], style: (
  shape: typ.shapes.triangle("angles", angles: (0deg, 120deg, 240deg)),
  min-size: 20pt,
)))

// Geometry resolves em against surrounding text before diagram zoom.
#set text(size: 10pt)
#typ.diagram(scale: 2, typ.edge(
  typ.node(0, 0, style: (shape: typ.shapes.diamond, min-size: 2em)),
  (2, 0), stroke: 0.1em + black,
))

// Standalone exported geometry helpers take a bare node and explicit zoom.
#context {
  let n = typ.box(0, 0, label: [A]).first()
  let prepared = typ.node-outline(n, size-factor: 0.8)
  let bounds = typ.outline-size(prepared.outline, prepared.measured)
  assert(bounds.width >= prepared.measured.width)
}
