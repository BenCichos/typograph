// Gate size accepts a length; comparing its resolved radius must support em.
#import "/src/lib.typ" as typ
#set text(size: 10pt)
#typ.diagram(typ.edge(typ.port(typ.gate(0, 0, none, size: 1em), "right"), (2, 0)))

#import "/src/node.typ": gate-port-on-outline
#context {
  let scalar = typ.gate(0, 0, none, size: 1em).first()
  let pair = typ.gate(0, 0, none, size: (1em, 1em)).first()
  assert(scalar == pair)
  assert(typ.node-outline(scalar, size-factor: 2).outline.half-width == 10pt)
  let mixed = typ.gate(0, 0, none, size: (2em - 5pt, 30pt - 1em)).first()
  let mixed-outline = typ.node-outline(mixed).outline
  assert(mixed-outline.half-width == 7.5pt and mixed-outline.half-height == 10pt)

  let gate = typ.gate(0, 0, none, port-spacing: 0.5em, legs: (right: 3)).first()
  let prep = typ.node-outline(gate, size-factor: 2)
  assert(prep.outline.half-height == 19pt)
  let a = gate-port-on-outline(prep.outline, gate.legs, "right", 0, port-spacing: 1em)
  let b = gate-port-on-outline(prep.outline, gate.legs, "right", 1, port-spacing: 1em)
  assert(calc.abs(a.at(1) - b.at(1)) == 10pt)

  // Layout's deferred port resolution must match the dimensions used to
  // prepare the node, including group and diagram zoom, without double zoom.
  let circuit(unit) = typ.group(scale: 1.5, {
    let g = typ.gate(0, 0, none, legs: (right: 3), port-spacing: 0.5 * unit)
    typ.edge(typ.port(g, "right", 0), (1, 1))
    typ.edge(typ.port(g, "right", 2), (1, -1))
  })
  assert(measure(typ.diagram(scale: 2, circuit(1em))) == measure(typ.diagram(scale: 2, circuit(10pt))))
  let inherited = typ.gate(0, 0, none, legs: (right: 3))
  let wire = typ.edge(typ.port(inherited, "right", 0), (2, 0))
  assert(measure(typ.diagram(port-spacing: 0.5em, wire)) == measure(typ.diagram(port-spacing: 5pt, wire)))
}
