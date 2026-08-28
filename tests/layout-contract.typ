// Contextual geometry assertions: a successful render alone cannot catch
// changes in measured dimensions, scaling, padding, or label inheritance.
#import "/src/lib.typ" as typ
#import "/src/node.typ": scale-inset

// A shifted inline baseline can add line-box extent. Measure the geometry
// with baseline fixed; the baseline formula is tested separately in unit.typ.
#let diagram = typ.diagram.with(baseline: 0pt)

#let near(a, b) = calc.abs((a - b) / 1pt) < 1e-5
#let same-size(a, b) = near(a.width, b.width) and near(a.height, b.height)
#let dot = typ.node-type("dot", base-style: (
  shape: typ.shapes.circle, min-size: 20pt, fill: blue, stroke: none,
))
#let pair = dot(0, 0) + dot(1, 0)

#set text(size: 10pt)
#context {
  assert(same-size(measure(diagram(inset: 0pt, none)), (width: 0pt, height: 0pt)))
  assert(same-size(measure(diagram(inset: 2pt, ())), (width: 4pt, height: 4pt)))
  let normal = measure(diagram(inset: 0pt, pair))
  let stretched = measure(diagram(inset: 0pt, scale-edges: 2, pair))
  let zoomed = measure(diagram(inset: 0pt, scale: 2, pair))
  assert(near(normal.width, 1cm + 20pt) and near(normal.height, 20pt))
  assert(near(stretched.width, 2cm + 20pt) and near(stretched.height, 20pt))
  assert(near(zoomed.width, 2 * normal.width) and near(zoomed.height, 2 * normal.height))
  assert(same-size(normal, measure(diagram(inset: 0pt, scale: 1cm, pair))))
  assert(same-size(zoomed, measure(diagram(inset: 0pt, typ.group(scale: 2, pair)))))
  assert(same-size(normal, measure(diagram(inset: 0pt, scale: 1cm, typ.group(dx: 11, dy: -7, pair)))))

  // Relative scale is resolved in the surrounding font context.
  assert(same-size(
    measure(diagram(inset: 0pt, scale: 2em, pair)),
    measure(diagram(inset: 0pt, scale: 20pt, pair)),
  ))

  // Diagram length margins stay absolute; numeric margins follow the grid.
  let absolute = measure(diagram(inset: 2pt, scale: 2, pair))
  let numeric = measure(diagram(inset: 0.2, scale: 2, scale-edges: 3, pair))
  assert(near(absolute.width - zoomed.width, 4pt))
  assert(near(numeric.width, 6cm + 40pt + 2.4cm))

  // All nine physical alignments affect bounds relative to another item.
  let body = rect(width: 6pt, height: 4pt, inset: 0pt, stroke: none)
  for ax in (left, center, right) {
    for ay in (top, horizon, bottom) {
      let size = measure(diagram(inset: 0pt, {
        typ.node(-1, -1)
        typ.place(0, 0, body, align: ax + ay)
      }))
      let rightward = if ax == left { 6pt } else if ax == center { 3pt } else { 0pt }
      let upward = if ay == top { 0pt } else if ay == horizon { 2pt } else { 4pt }
      assert(near(size.width, 1cm + rightward))
      assert(near(size.height, 1cm + upward))
    }
  }
  assert(same-size(
    measure(diagram(inset: 0pt, typ.place(0, 0, body, align: left))),
    measure(diagram(inset: 0pt, typ.place(0, 0, body, align: left + horizon))),
  ))
  let content-only = typ.place(0, 0, body)
  assert(same-size(
    measure(diagram(inset: 0pt, content-only)),
    measure(diagram(inset: 0pt, scale: 3, typ.group(scale: 2, content-only))),
  ), message: "place content retains its own size under diagram/group zoom")

  // Label sizing: diagram font-size, per-node font-size, and zoom compose.
  let label = typ.node(0, 0, label: [Ag], style: (shape: typ.shapes.bare)).first()
  let inherited = typ.node-outline(label)
  let large = typ.node-outline(label, font-size: 20pt)
  assert(near(large.measured.width, inherited.measured.width * 2))
  assert(near(large.measured.height, inherited.measured.height * 2))
  let own = label + (style: label.style + (font-size: 10pt))
  assert(same-size(typ.node-outline(own, font-size: 30pt).measured, inherited.measured))
  assert(same-size(typ.node-outline(own, size-factor: 2).measured, large.measured))

  // size is a minimum, not a hard box: a large label may still enlarge it.
  let g = typ.gate(0, 0, rect(width: 30pt, height: 10pt), size: 2pt, inset: 0pt).first()
  let outline = typ.node-outline(g).outline
  assert(near(outline.half-width * 2, 30pt))
  assert(near(outline.half-height * 2, 10pt))
}

// Node numeric padding means reference-scale points, not coordinate units.
// Its opposite-side sum sizes the box, and the difference offsets the label.
#let pad-node(inset) = typ.node(0, 0, style: (shape: typ.shapes.rect, inset: inset)).first()
#let numeric-pad = typ.node-outline(pad-node(2), size-factor: 3).outline
#let length-pad = typ.node-outline(pad-node(2pt), size-factor: 3).outline
#assert(numeric-pad == length-pad and near(numeric-pad.half-width, 6pt))
#let asym = typ.node-outline(pad-node((left: 5pt, right: 1pt, top: 4pt, bottom: 2pt)), size-factor: 2).outline
#assert(asym.label-offset == (4pt, 2pt))
#assert(scale-inset((left: 50%, right: 20% + 2pt, rest: 3pt), 2) == (left: 50%, right: 20% + 4pt, rest: 6pt))

// Compact unlabeled gates preserve explicit/theme minima and scalar sizes;
// explicit padding and multi-port fan-out still impose their own floors.
#let compact = typ.gate(0, 0, none, legs: (right: 1)).first()
#assert(near(typ.node-outline(compact, preset: (min-size: 2pt)).outline.half-width, 1pt))
#assert(near(typ.node-outline(compact, override: (min-size: 3pt)).outline.half-height, 1.5pt))
#let padded = typ.gate(0, 0, none, size: 1pt, inset: 2pt).first()
#assert(near(typ.node-outline(padded).outline.half-width, 2pt))
#for size in (0pt, 1pt, 17pt) {
  let scalar = typ.gate(0, 0, none, size: size).first()
  let pair = typ.gate(0, 0, none, size: (size, size)).first()
  assert(scalar == pair)
  assert(near(typ.node-outline(scalar).outline.half-width, size / 2))
}
#let many = typ.gate(0, 0, none, legs: (top: 3, right: 4), style: (min-size: 0pt)).first()
#let inherited-spacing = typ.node-outline(many, port-spacing: 5pt, size-factor: 2).outline
#assert(near(inherited-spacing.half-width, 22pt))
#assert(near(inherited-spacing.half-height, 24pt))
#let own-spacing = many + (port-spacing: 3pt)
#assert(near(typ.node-outline(own-spacing, port-spacing: 9pt).outline.half-height, 9pt))

// Composite parts use an empty label measure and the base silhouette alone
// controls wire clipping. Translated parts still extend visual bounds.
#let composite = typ.node(0, 0, style: (
  shape: typ.shapes.circle, min-size: 10pt,
  "shape.parts": (
    badge: (shape: typ.shapes.rect, min-size: 4pt, transform: (x: 20pt, y: -10pt)),
  ),
)).first()
#let prep = typ.node-outline(composite, size-factor: 2)
#let bounds = typ.outline-size(prep.outline, prep.measured)
#assert(prep.outline.parts.first().transform == (40pt, -20pt))
#assert(near(bounds.left, -10pt) and near(bounds.right, 44pt))
#assert(near(bounds.top, -24pt) and near(bounds.bottom, 10pt))
#assert(typ.shape-radius(prep.outline, 0deg) == 10pt)

// Each node precedence layer expands min-size independently. Extension data
// is preserved, while nested inset dictionaries replace rather than merge.
#let layered = typ.node(0, 0, kind: "custom", base-style: (min-width: 30pt), style: (min-height: 7pt)).first()
#let resolved = typ.node-outline(layered, preset: (min-size: 20pt), override: (min-size: 10pt)).style
#assert(resolved.min-width == 10pt and resolved.min-height == 7pt)
#let extension = typ.resolve-node-style("custom", (:), (custom-ratio: 0.4, inset: (left: 4pt)), (inset: (right: 2pt)))
#assert(extension.custom-ratio == 0.4 and extension.inset == (right: 2pt))

// Every edge layer beats the preceding one, including theme defaults below
// factory defaults, and auto/none have distinct direct-argument meanings.
#let edge(overrides: (:), ..args) = typ.edge((0, 0), (1, 0), ..args, ..overrides).first()
#let edge-style(e, overrides: (:)) = typ.resolve-edge-style(
  e, overrides, defaults: (stroke: 1pt + red, highlight: blue),
  presets: (named: (stroke: 3pt + purple)),
)
#assert(edge-style(edge()).stroke == 1pt + red)
#assert(edge-style(edge(base-style: (stroke: 2pt + green))).stroke == 2pt + green)
#assert(edge-style(edge(base-style: (stroke: 2pt + green), preset: "named")).stroke == 3pt + purple)
#assert(edge-style(edge(preset: "named"), overrides: (stroke: 4pt + orange)).stroke == 4pt + orange)
#assert(edge-style(edge(style: (stroke: 5pt + yellow)), overrides: (stroke: 4pt + orange)).stroke == 5pt + yellow)
#assert(edge-style(edge(stroke: none, style: (stroke: 5pt + yellow))).stroke == none)
#assert(edge-style(edge(highlight: auto)).highlight == blue)
#assert(edge-style(edge(highlight: none)).highlight == ())
#assert(edge-style(edge(highlight: ())).highlight == ())
