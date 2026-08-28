// Contextual contract for the state-backed config stack.
#import "/src/config.typ": config, current-defaults
#import "/src/lib.typ" as typ

#let near(a, b) = calc.abs((a - b) / 1pt) < 1e-5
#let measure-wire(..opts) = measure(typ.diagram(
  inset: 0pt, baseline: 0pt,
  typ.edge((0, 0), (1, 0), stroke: none),
  ..opts,
))

#config(
  scale: 0.8cm,
  baseline: 6pt,
  port-spacing: 8pt,
  node-styles: (z: (fill: red), x: (fill: blue)),
  edge-styles: (highlight-width: 4pt),
)[
  #config(
    node-styles: (z: (stroke: 1pt + black)),
    edge-styles: (label-offset: 3pt),
  )[
    #context {
      let current = current-defaults()
      assert(current.scale == 0.8cm)
      assert(current.baseline == 6pt)
      assert(current.port-spacing == 8pt)
      assert(current.node-styles.z.fill == red)
      assert(current.node-styles.z.stroke == 1pt + black)
      assert(current.node-styles.x.fill == blue)
      assert(current.edge-styles.highlight-width == 4pt)
      assert(current.edge-styles.label-offset == 3pt)
    }
  ]
  #context {
    let current = current-defaults()
    assert(current.scale == 0.8cm)
    assert(current.baseline == 6pt)
    assert(current.port-spacing == 8pt)
    assert(current.node-styles.z.fill == red)
    assert("stroke" not in current.node-styles.z)
    assert(current.edge-styles.highlight-width == 4pt)
    assert("label-offset" not in current.edge-styles)
  }
]

#context {
  let current = current-defaults()
  assert("scale" not in current)
  assert("baseline" not in current)
  assert("port-spacing" not in current)
  assert("node-styles" not in current)
  assert("edge-styles" not in current)
}

// Exercise the renderer as well as the state record. Explicit call options
// beat config, nested config restores its parent, and siblings do not leak.
#config(scale: 2, scale-edges: 3)[
  #context {
    assert(near(measure-wire().width, 6cm))
    assert(near(measure-wire(scale: 1).width, 3cm))
    assert(near(measure-wire(scale: 1, scale-edges: 1).width, 1cm))
  }
  #config(scale-edges: 1)[
    #context { assert(near(measure-wire().width, 2cm)) }
  ]
  #context { assert(near(measure-wire().width, 6cm)) }
]
#context { assert(near(measure-wire().width, 1cm)) }

// A later min-size resets both inherited axes, then one explicit axis wins
// within that same layer; unrelated kinds and keys survive nested merging.
#config(node-styles: (a: (min-width: 30pt, fill: red), b: (min-size: 8pt)))[
  #config(node-styles: (a: (min-size: 10pt, min-height: 12pt)))[
    #context {
      let styles = current-defaults().node-styles
      assert(styles.a.min-width == 10pt and styles.a.min-height == 12pt)
      assert(styles.a.fill == red)
      assert(styles.b.min-width == 8pt and styles.b.min-height == 8pt)
    }
  ]
  #context { assert(current-defaults().node-styles.a.min-width == 30pt) }
]
