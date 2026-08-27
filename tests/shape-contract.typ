// Function-valued shape API contract, including the standard-library-backed
// shapes, fitted regular polygons, and arbitrary polygon factories.
#import "/src/lib.typ" as typ
#import "/src/node.typ": (
  shape-outline, outline-size, node-visual-spec, node-outline,
)
#import "/src/shape.typ": build-outline

#let approx-length(a, b) = calc.abs(a / 1pt - b / 1pt) < 1e-6
#let measured = (width: 10pt, height: 6pt)
#let style(shape, ..extra) = typ.resolve-node-style(
  "node",
  (:),
  (shape: shape, min-width: 20pt, min-height: 12pt, inset: 2pt)
    + extra.named(),
)
#let outline(shape, label: [x], ..extra) = shape-outline(
  style(shape, ..extra.named()),
  label,
  if label == [] { (width: 0pt, height: 0pt) } else { measured },
)

#for builder in (
  typ.shapes.empty,
  typ.shapes.bare,
  typ.shapes.circle,
  typ.shapes.ellipse,
  typ.shapes.stadium,
  typ.shapes.rect,
  typ.shapes.square,
  typ.shapes.triangle,
  typ.shapes.flat-triangle,
  typ.shapes.trapezoid,
  typ.shapes.arrow,
  typ.shapes.diamond,
  typ.shapes.hexagon,
) {
  assert(type(builder) == function)
}

#assert(outline(typ.shapes.empty).kind == "empty")
#assert(outline(typ.shapes.bare).kind == "bare")
#assert(outline(typ.shapes.circle).kind == "circle")
#assert(outline(typ.shapes.ellipse).kind == "ellipse")
#assert(outline(typ.shapes.rect).kind == "rect")
#assert(outline(typ.shapes.square).kind == "rect")
#assert(outline(typ.shapes.triangle).kind == "polygon")
#let isosceles-triangle = outline(typ.shapes.triangle("isosceles", ratio: 0.5))
#let default-triangle = outline(typ.shapes.triangle)
#let isosceles-by-mode = outline(typ.shapes.triangle(mode: "isosceles", ratio: 0.5))
#let isos-range = calc.max(..isosceles-triangle.points.map(point => point.at(0)))
  - calc.min(..isosceles-triangle.points.map(point => point.at(0)))
#let default-range = calc.max(..default-triangle.points.map(point => point.at(0)))
  - calc.min(..default-triangle.points.map(point => point.at(0)))
#assert(isos-range < default-range)
#let flipped-isos = outline(typ.shapes.triangle("isosceles", ratio: 0.5), flip: true)
#let isosceles-xs = isosceles-triangle.points.map(point => point.at(0))
#let flipped-xs = flipped-isos.points.map(point => point.at(0))
#assert(approx-length(calc.max(..isosceles-xs), -calc.min(..flipped-xs)))
#assert(approx-length(calc.min(..isosceles-xs), -calc.max(..flipped-xs)))
#let angled = outline(typ.shapes.triangle("angles", angles: (20deg, 220deg, 100deg)))
#assert(angled.kind == "polygon" and angled.points.len() == 3)
#assert(isosceles-by-mode.kind == "polygon" and isosceles-by-mode.points.len() == 3)
#assert(outline(typ.shapes.hexagon).points.len() == 6)
#assert(outline(typ.shapes.broad-triangle).kind == "polygon")

#let pill = outline(typ.shapes.stadium)
#assert(pill.kind == "rect")
#assert(pill.radius == calc.min(pill.half-width, pill.half-height))
#let square-outline = outline(typ.shapes.square)
#assert(approx-length(square-outline.half-width, square-outline.half-height))
#let zero-inset = shape-outline(
  typ.resolve-node-style("node", (:), (
    shape: typ.shapes.circle,
    min-size: 9pt,
    inset: 0pt,
  )),
  [],
  (width: 0pt, height: 0pt),
)
#assert(approx-length(2 * zero-inset.radius, 9pt))

// The vertex count is the public edge-count API for regular polygons.
#let heptagon-builder = typ.shapes.regular(vertices: 7, rotate: -90deg)
#let heptagon = outline(heptagon-builder, label: [])
#assert(heptagon.kind == "polygon" and heptagon.points.len() == 7)
#let radii = heptagon.points.map(point => {
  let x = point.at(0) / 1pt
  let y = point.at(1) / 1pt
  calc.sqrt(x * x + y * y)
})
#assert(radii.all(radius => calc.abs(radius - radii.first()) < 1e-6))

// Template validity is scale-invariant; normalized geometry should not be
// rejected merely because its author chose very small unitless coordinates.
#let tiny-triangle = typ.shapes.polygon(
  ((1e-12, 0), (-5e-13, 8.660254e-13), (-5e-13, -8.660254e-13)),
)
#assert(outline(tiny-triangle, label: []).points.len() == 3)

// ZXDraw previews custom styles with an unlabelled sample. A valid polygon
// must not collapse when that sample has no label, inset, or minimum size.
#let unlabelled-triangle = typ.shapes.polygon(
  ((-1, 0), (1, -1), (1, 1)),
  anchor: (0, 0),
)
#let unlabelled-outline = shape-outline(
  typ.resolve-node-style("node", (:), (shape: unlabelled-triangle)),
  [],
  (width: 0pt, height: 0pt),
)
#assert(unlabelled-outline.half-width > 0pt)
#assert(unlabelled-outline.half-height > 0pt)
#assert(unlabelled-outline.points.len() == 3)

// An arbitrary polygon is normalized about its anchor, scaled uniformly to
// its label box, and exposes accurate bounds after per-node rotation.
#let kite-builder = typ.shapes.polygon(
  ((0, -1), (1, 0), (0.25, 1), (-1, 0.25), (-0.65, -0.6)),
  anchor: (0, 0),
  clearance: (1.2, 1.1),
  label-offset: (0, 0.08),
)
#let kite = outline(kite-builder, rotate: 37deg)
#assert(kite.points.len() == 5)
#assert(kite.points.all(point => calc.abs(point.at(0)) <= kite.half-width))
#assert(kite.points.all(point => calc.abs(point.at(1)) <= kite.half-height))
#assert(kite.label-offset != (0pt, 0pt))

// The low-level escape hatch derives extents from the actual points. Builder
// validation recomputes them too, so a custom builder cannot under-report
// bounds and make clipping/layout unsafe.
#let low = typ.polygon-outline(
  ((-11pt, -3pt), (7pt, -5pt), (9pt, 4pt), (-4pt, 8pt)),
  label-offset: (1pt, -2pt),
)
#assert(low.half-width == 11pt and low.half-height == 8pt)
#assert(low.label-offset == (1pt, -2pt))
#let under-reported(label, pad, style) = (
  kind: "polygon",
  points: ((-12pt, -2pt), (6pt, -4pt), (8pt, 7pt)),
  half-width: 1pt,
  half-height: 1pt,
  label-offset: (0pt, 0pt),
)
#let validated = build-outline(
  under-reported,
  measured,
  (left: 0pt, right: 0pt, top: 0pt, bottom: 0pt),
  style(under-reported),
)
#assert(validated.half-width == 12pt and validated.half-height == 7pt)

// Opposite inset sums size the outline; their difference positions the label
// in the remaining content area, matching Typst's per-side inset semantics.
#let asymmetric = shape-outline(
  style(typ.shapes.rect, inset: (
    left: 10pt, right: 2pt, top: 7pt, bottom: 1pt,
  )),
  [x],
  measured,
)
#assert(asymmetric.label-offset == (4pt, 3pt))

// A deliberately displaced label participates in diagram bounds instead of
// being cropped at the silhouette or outer diagram edge.
#let shifted-builder(label, pad, style) = typ.polygon-outline(
  ((-5pt, -5pt), (5pt, -5pt), (5pt, 5pt), (-5pt, 5pt)),
  label-offset: (20pt, 0pt),
)
#let shifted = shape-outline(
  style(shifted-builder, inset: 0pt), [wide], measured,
)
#let shifted-bounds = outline-size(shifted, measured)
#assert(shifted-bounds.left == -5pt)
#assert(shifted-bounds.right == 20pt + measured.width / 2)
#assert(shifted-bounds.width == shifted-bounds.right - shifted-bounds.left)

#let cross-style = typ.resolve-node-style("node", (:), (
  shape: typ.shapes.circle,
  min-width: 20pt,
  min-height: 12pt,
  inset: 2pt,
  "shape.parts": (
    (
      shape: typ.shapes.triangle("isosceles", ratio: 0.55),
      fill: none,
      stroke: 0.6pt + black,
      transform: (0pt, -1pt),
      min-width: 12pt,
      min-height: 6pt,
    ),
  ),
  mark: "cross",
  mark-stroke: 0.6pt + black,
  mark-size: 6pt,
  mark-thickness: 0.6pt,
))
#let cross-state = shape-outline(
  cross-style,
  [],
  measured,
)
#assert(cross-state.kind == "parts")
#assert(cross-state.parts.len() == 2)

// Percentage-sized crosses follow the resolved base silhouette below 6pt,
// and their filled band uses the scaled mark stroke without a device-space
// minimum. These values describe a 4pt target-like node at half scale.
#let scaled-cross-node = typ.node(0, 0, style: (
  shape: typ.shapes.circle,
  min-size: 4pt,
  inset: 0pt,
  stroke: none,
  mark: "cross",
  mark-stroke: 0.6pt + black,
  mark-size: 100%,
  mark-thickness: auto,
  mark-angle: 0deg,
)).first()
#let scaled-cross = node-outline(scaled-cross-node, size-factor: 0.5).outline
#let scaled-cross-part = scaled-cross.parts.first().outline
#let full-cross-part = node-outline(
  scaled-cross-node,
  size-factor: 1,
).outline.parts.first().outline
#assert(approx-length(scaled-cross.base.outline.radius, 1pt))
#assert(approx-length(scaled-cross-part.half-width, 1pt))
#assert(approx-length(calc.abs(scaled-cross-part.points.first().at(0)), 0.15pt))
#assert(approx-length(full-cross-part.half-width, 2pt))
#assert(approx-length(calc.abs(full-cross-part.points.first().at(0)), 0.3pt))

#let auto-cross-node = typ.node(0, 0, style: (
  shape: typ.shapes.circle,
  min-size: 4pt,
  inset: 0pt,
  stroke: none,
  mark: "cross",
  mark-stroke: 0.6pt + black,
  mark-size: auto,
  mark-angle: 0deg,
)).first()
#let half-auto-cross = node-outline(
  auto-cross-node,
  size-factor: 0.5,
).outline.parts.first().outline
#let full-auto-cross = node-outline(
  auto-cross-node,
  size-factor: 1,
).outline.parts.first().outline
#assert(approx-length(half-auto-cross.half-width, 1.5pt))
#assert(approx-length(full-auto-cross.half-width, 3pt))

// A fill-only cross has no pen to supply Typst's default 1pt thickness, so
// that fallback must explicitly follow the diagram scale too.
#let fill-only-cross = typ.node(0, 0, style: (
  shape: typ.shapes.circle,
  min-size: 4pt,
  inset: 0pt,
  stroke: none,
  mark: "cross",
  mark-fill: red,
  mark-stroke: none,
  mark-size: 100%,
  mark-thickness: auto,
  mark-angle: 0deg,
)).first()
#let fill-only-part = node-outline(
  fill-only-cross,
  size-factor: 0.5,
).outline.parts.first().outline
#assert(approx-length(calc.abs(fill-only-part.points.first().at(0)), 0.25pt))

// Part-local lengths scale like the base style, while a percentage radius is
// dimensionless and must not be treated as a relative-length record.
#let scaled-part-radius(radius, factor) = {
  let n = typ.node(0, 0, style: (
    shape: typ.shapes.circle,
    min-size: 8pt,
    inset: 0pt,
    "shape.parts": ((
      shape: typ.shapes.rect,
      min-size: 8pt,
      inset: 0pt,
      radius: radius,
      fill: none,
      stroke: none,
    ),),
  )).first()
  node-outline(n, size-factor: factor).outline.parts.first().outline.radius
}
#assert(approx-length(scaled-part-radius(50%, 0.5), 1pt))
#assert(approx-length(scaled-part-radius(1pt, 0.5), 0.5pt))
#assert(approx-length(scaled-part-radius(50% + 1pt, 0.5), 1.5pt))

#let part-floor-node = typ.node(0, 0, style: (
  shape: typ.shapes.circle,
  min-size: 20pt,
  inset: 0pt,
  "shape.parts": ((
    shape: typ.shapes.rect,
    min-size: 6pt,
    inset: 0pt,
    fill: none,
    stroke: none,
  ),),
)).first()
#let scaled-part-floor = node-outline(
  part-floor-node,
  size-factor: 0.5,
).outline.parts.first().outline
#assert(approx-length(scaled-part-floor.half-width * 2, 3pt))
#assert(approx-length(scaled-part-floor.half-height * 2, 3pt))

#let measurement-mark = shape-outline(
  style(
    typ.shapes.rect,
    mark: "measurement",
    mark-stroke: 1.2pt + red,
    mark-size: 14pt,
    mark-angle: -45deg,
  ),
  [],
  measured,
)
#assert(measurement-mark.kind == "parts")
#assert(measurement-mark.parts.len() == 3)
#assert(measurement-mark.parts.all(part => part.layer == "behind"))
#let measurement-bounds = outline-size(measurement-mark, measured)
#assert(measurement-bounds.left < 0pt and measurement-bounds.right > 0pt)
#assert(measurement-bounds.top < -measurement-mark.base.outline.half-height)

// Port capability alone must not enlarge a compact one-port marker. Multiple
// ports do grow the corresponding axis from their exact center spacing plus
// the established gate margin.
#let compact-gate = typ.gate(
  0, 0, none,
  legs: (right: 1),
  style: (shape: typ.shapes.circle, min-size: 3pt, inset: 0pt),
).first()
#assert(approx-length(node-outline(compact-gate).outline.radius, 1.5pt))

#let multi-port-height(spacing) = {
  let n = typ.gate(
    0, 0, none,
    legs: (right: 3),
    port-spacing: spacing,
    style: (shape: typ.shapes.rect, min-size: 0pt, inset: 0pt),
  ).first()
  node-outline(n).outline.half-height * 2
}
#assert(approx-length(multi-port-height(3pt), 15pt))
#assert(approx-length(multi-port-height(7pt), 23pt))
#assert(approx-length(multi-port-height(10pt), 29pt))

// shape-labelled is also a builder, so users can opt into a different form
// without coupling a node kind to either geometry.
#assert(shape-outline(
  style(typ.shapes.circle, shape-labelled: typ.shapes.stadium),
  [long],
  (width: 22pt, height: 6pt),
).kind == "rect")

// Presence, not content truthiness, selects shape-labelled. An explicit empty
// label still means the caller supplied a label.
#let empty-label-node = typ.node(
  0, 0, label: [],
  base-style: (
    shape: typ.shapes.circle,
    shape-labelled: typ.shapes.stadium,
    min-size: 10pt,
  ),
).first()
#context {
  assert(node-outline(node-visual-spec(empty-label-node)).outline.kind == "rect")
}

// Native Typst shape names remain usable because package builders are
// namespaced under typ.shapes.
#circle(radius: 2pt, fill: black)
#rect(width: 8pt, height: 4pt, fill: gray)
#polygon(fill: silver, (0pt, 0pt), (8pt, 0pt), (4pt, 6pt))

// Rendering exercises all outline kinds through the public neutral facade.
#typ.diagram({
  let builders = (
    typ.shapes.circle,
    typ.shapes.ellipse,
    typ.shapes.stadium,
    typ.shapes.rect,
    typ.shapes.square,
    typ.shapes.regular(vertices: 5),
    kite-builder,
  )
  for (index, builder) in builders.enumerate() {
    typ.node(index * 0.8, 0, label: [#index], style: (
      shape: builder,
      fill: white,
      stroke: 0.5pt + black,
      min-size: 12pt,
      inset: 2pt,
    ))
  }
  typ.node(0, -0.8, label: [A], style: (
    shape: typ.shapes.rect,
    fill: white,
    stroke: 0.5pt + black,
    inset: (left: 10pt, right: 2pt, top: 7pt, bottom: 1pt),
  ))
})
