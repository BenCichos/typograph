// config claims to accept the non-theme diagram arguments. auto should not
// turn a valid diagram argument into an invalid concrete scale.
#import "/src/lib.typ" as typ
#typ.config(scale: auto)[#typ.diagram(typ.edge((0, 0), (1, 0)))]

#import "/src/config.typ": current-defaults
#let inherit = (
  scale: auto, scale-edges: auto, grid: auto, inset: auto, anchor: auto,
  math-axis: auto, port-spacing: auto, node-styles: auto, edge-styles: auto,
)
#typ.config(..inherit)[
  #context { assert(current-defaults() == (:)) }
  #typ.diagram(typ.edge((0, 0), (1, 0)))
]

#let parent = (
  scale: 2, scale-edges: 3, font-size: 17pt, baseline: 5pt, grid: false,
  inset: 2pt, anchor: 1, math-axis: 3pt, port-spacing: 9pt,
  node-styles: (custom: (fill: red)), edge-styles: (label-offset: 4pt),
)
#typ.config(..parent)[
  #typ.config(..inherit)[
    #context { assert(current-defaults() == parent) }
    #typ.diagram(typ.edge((0, 0), (1, 0)))
    // These two keys already have meaningful automatic behavior: an inner
    // scope can explicitly restore document text size / calculated baseline.
    #typ.config(font-size: auto, baseline: auto)[
      #context {
        assert(current-defaults() == parent + (font-size: auto, baseline: auto))
      }
      #typ.diagram(typ.box(0, 0, label: [Ag]))
    ]
    #context { assert(current-defaults() == parent) }
  ]
  #context { assert(current-defaults() == parent) }
]
#context { assert(current-defaults() == (:)) }
