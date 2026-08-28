// Compiles through the manifest/package loader rather than a source-relative
// import, catching entrypoint and facade regressions.
#import "@preview/typograph:0.3.0" as typ

#let diagram = typ.diagram

#assert(typ.node(0, 0).first().kind == "node")
#assert(typ.node-type("neutral")(0, 0).first().kind == "neutral")
#assert(typ.neutral-theme.node-presets == (:))
#assert(type(typ.shapes.circle) == function)
#assert(type(typ.offset) == function)

#diagram({ typ.edge(typ.node(0, 0), typ.box(1, 0)) })
#diagram({
  let g = typ.gate((0, 0), [U])
  let p = typ.port(g, "right")
  let n = typ.box(typ.offset(p, 1, 0), label: [A])
  typ.edge(p, n)
  typ.place(p.x, -1, [caption])
})
