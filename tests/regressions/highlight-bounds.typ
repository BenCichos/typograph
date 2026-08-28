// Even a highlight's centerline must fit inside the declared visual bounds.
// This acute turn extends ~3.98pt to the right (formerly only 2pt outset).
#import "/src/lib.typ" as typ
#import "/src/diagram.typ": edge-visual-radius, offset-polyline
#let points = ((0pt, 0pt), (10pt, 0pt), (0pt, 2pt))
#let style = typ.edge-defaults + (stroke: none, highlight-width: 4pt)
#let extent = edge-visual-radius(style, (red, blue), 1, miter: true)
#let shifted = offset-polyline(points, -1pt)
#assert(
  shifted.at(1).at(0) <= 10pt + extent,
  message: "highlight centerline exceeds declared bounds",
)

#import "/src/diagram.typ": sample-path-screen
#import "/src/edge.typ": resolve-edge-path
#for turn in (1deg, 10deg, 45deg, 90deg, 150deg, 170deg, 179deg) {
  let points = ((0pt, 0pt), (10pt, 0pt), (10pt + 10pt * calc.cos(turn), 10pt * calc.sin(turn)))
  for width in (1pt, 4pt, 10pt) {
    for extra in (-6pt, -1pt, 0pt, 5pt) {
      for zoom in (0.5, 2) {
        let style = typ.edge-defaults + (stroke: none, highlight-width: width, highlight-offset: extra)
        let radius = edge-visual-radius(style, (red, blue), zoom, miter: true)
        let offset = (extra + width / 4) * zoom
        for side in (-1, 1) {
          let shifted = offset-polyline(points, side * offset)
          for (original, actual) in points.zip(shifted) {
            for axis in (0, 1) {
              // Includes the band's half-thickness, not just its centerline.
              assert(calc.abs(actual.at(axis) - original.at(axis)) + width * zoom / 4 <= radius + 0.000001pt)
            }
          }
        }
      }
    }
  }
}

// Single-segment Beziers still produce multi-joint highlight polylines.
#context {
  for edge in (
    typ.edge((0, 0), typ.quad((1, 2), (2, 0))),
    typ.edge((0, 0), typ.cubic((1, 3), (-1, 3), (2, 0))),
  ) {
    let path = resolve-edge-path(edge.first())
    assert(path.segments.len() == 1 and sample-path-screen(path, 1cm).len() > 2)
    let bare = measure(typ.diagram(inset: 0pt, baseline: 0pt, edge-styles: (stroke: none), edge))
    let banded = measure(typ.diagram(inset: 0pt, baseline: 0pt, edge-styles: (
      stroke: none, highlight: red, highlight-width: 4pt, highlight-offset: 5pt,
    ), edge))
    let radius = edge-visual-radius(typ.edge-defaults + (
      stroke: none, highlight-width: 4pt, highlight-offset: 5pt,
    ), (red, red), 1, highlight-joins: true)
    assert(calc.abs(banded.width - bare.width - 2 * radius) < 0.000001pt)
    assert(calc.abs(banded.height - bare.height - 2 * radius) < 0.000001pt)
  }
}

// A single straight edge retains the tight pre-existing band bound.
#assert(edge-visual-radius(style, (red, blue), 1) == 2pt)
