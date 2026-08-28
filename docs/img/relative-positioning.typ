// Same relative layout with two differently sized gate labels.
#import "../../src/lib.typ" as typ
#set page(width: auto, height: auto, margin: 8pt)
#set text(size: 9pt)
#let example(label) = typ.diagram(inset: 0.15, {
  let g = typ.gate((0, 0), label)
  let p = typ.port(g, "right")
  let a = typ.box(typ.offset(p, 1.4, 0), label: [A], fill: rgb("e8efff"))
  let b = typ.box(p.x, -1.2, label: [B], fill: rgb("e4f5ec"))
  typ.edge(p, a)
  typ.edge(p, b, stroke: (paint: gray, thickness: 0.6pt, dash: "dashed"))
  typ.node(p, style: (shape: typ.shapes.circle, min-size: 3pt, inset: 0pt, fill: black, stroke: none))
  typ.place(typ.offset(p, 0.7, 0.4), [both axes])
  typ.place(p.x, -1.65, [same port x])
})
#stack(dir: ttb, spacing: 12pt, example([U]), example([a wider gate label]))
