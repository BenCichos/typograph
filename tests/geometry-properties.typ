// Deterministic property grids: check geometry identities, not just examples
// of successful compilation. Keep these context-free and font-independent.
#import "/src/lib.typ" as typ
#import "/src/edge.typ": (
  resolve-edge-path, point-on-segment, split-segment, trim-resolved-at,
  path-metrics, point-on-path, segment-metrics, segment-t-at-length,
)
#import "/src/geometry.typ": ellipse-radius, rounded-rect-radius, polygon-radius
#import "/src/node.typ": gate-port-on-outline
#import "/src/diagram.typ": numeric-outline, outline-contains-point

#let close(a, b, epsilon: 1e-7) = calc.abs(a - b) < epsilon
#let point-close(a, b) = a.zip(b).all(pair => close(..pair))
#let length-close(a, b) = close(a / 1pt, b / 1pt)
#let start = (-2, 1)
#let segments = (
  (kind: "line", ctrl: (), end: (3, -2)),
  (kind: "quad", ctrl: ((7, 5),), end: (3, -2)),
  (kind: "cubic", ctrl: ((-4, 7), (8, -6)), end: (3, -2)),
  // A loop and a stationary endpoint exercise non-monotonic coordinates.
  (kind: "cubic", ctrl: ((6, 8), (-5, 3)), end: start),
  (kind: "cubic", ctrl: (start, (3, -2)), end: (3, -2)),
)

#for seg in segments {
  for split-at in (0, 0.01, 0.2, 0.5, 0.9, 1) {
    let split = split-segment(start, seg, split-at)
    assert(split.left.kind == seg.kind and split.right.kind == seg.kind)
    assert(split.left.ctrl.len() == seg.ctrl.len())
    assert(split.right.ctrl.len() == seg.ctrl.len())
    assert(point-close(split.point, point-on-segment(start, seg, split-at)))
    for u in (0, 0.125, 0.5, 0.875, 1) {
      assert(point-close(
        point-on-segment(start, split.left, u),
        point-on-segment(start, seg, u * split-at),
      ), message: "left de Casteljau split preserves the original curve")
      assert(point-close(
        point-on-segment(split.point, split.right, u),
        point-on-segment(start, seg, split-at + u * (1 - split-at)),
      ), message: "right de Casteljau split preserves the original curve")
    }
  }
  let path = (start: start, segments: (seg,), straight: seg.kind == "line")
  for interval in ((0, 1), (0.1, 0.9), (0.2, 0.3), (0.75, 1)) {
    let (lo, hi) = interval
    let trimmed = trim-resolved-at(
      path, start-location: (segment: 0, t: lo), end-location: (segment: 0, t: hi),
    )
    for u in (0, 0.25, 0.5, 0.75, 1) {
      assert(point-close(
        point-on-segment(trimmed.start, trimmed.segments.first(), u),
        point-on-segment(start, seg, lo + u * (hi - lo)),
      ), message: "parameter-space trim preserves the original curve")
    }
  }
  let metrics = segment-metrics(start, seg)
  assert(metrics.cumulative.first() == 0)
  assert(metrics.cumulative.last() == metrics.length)
  assert(metrics.cumulative.sorted() == metrics.cumulative)
  assert(segment-t-at-length(metrics, -1) == 0)
  assert(segment-t-at-length(metrics, metrics.length + 1) == 1)
}

// Reversing a mixed path preserves its sampled physical length and maps
// distance fractions t <-> 1-t, including repeated zero-length segments.
#let path = resolve-edge-path(typ.edge(
  (0, 0), (0, 0), typ.quad((1, 3), (4, 0)),
  typ.cubic((5, -2), (7, 1), (8, 0)), (8, 0),
).first())
#let info = path-metrics(path)
#let reversed = (
  start: path.segments.last().end,
  straight: false,
  segments: path.segments.enumerate().rev().map(pair => (
    kind: pair.at(1).kind,
    ctrl: pair.at(1).ctrl.rev(),
    end: info.starts.at(pair.at(0)),
  )),
)
#assert(close(path-metrics(reversed).length, info.length))
#for t in (0, 0.1, 0.25, 0.5, 0.9, 1) {
  assert(point-close(point-on-path(path, t), point-on-path(reversed, 1 - t)))
  assert(point-close(point-on-path(path, t), point-on-path(path, t, metrics: info)))
}
#let stationary = resolve-edge-path(typ.edge((3, 4), (3, 4), (3, 4)).first())
#assert(point-on-path(stationary, 0.5) == (3, 4))

// Ray queries must agree with independent circle/ellipse equations and the
// rounded-rectangle containment predicate on either side of the boundary.
#for degree in range(0, 360, step: 7) {
  let angle = degree * 1deg
  let r = ellipse-radius(13pt, 7pt, angle) / 1pt
  let x = r * calc.cos(angle)
  let y = r * calc.sin(angle)
  assert(close((x / 13) * (x / 13) + (y / 7) * (y / 7), 1))
  assert(length-close(rounded-rect-radius(9pt, 9pt, 100pt, angle), 9pt))
  let rounded = (kind: "rect", half-width: 13pt, half-height: 7pt, radius: 3pt)
  let boundary = rounded-rect-radius(13pt, 7pt, 3pt, angle) / 1pt
  let inner = ((boundary - 0.01) * calc.cos(angle), -(boundary - 0.01) * calc.sin(angle))
  let outer = ((boundary + 0.01) * calc.cos(angle), -(boundary + 0.01) * calc.sin(angle))
  assert(outline-contains-point(numeric-outline(rounded), (0, 0), inner, 1))
  assert(not outline-contains-point(numeric-outline(rounded), (0, 0), outer, 1))
}
#assert(ellipse-radius(0pt, 0pt, 45deg) == 0pt)
#assert(length-close(ellipse-radius(0pt, 4pt, 90deg), 4pt))
#assert(ellipse-radius(0pt, 4pt, 0deg) == 0pt)
#assert(length-close(ellipse-radius(4pt, 0pt, 180deg), 4pt))

// Polygon rays are independent of winding and rotate with the vertices.
#let points = ((-8pt, -6pt), (11pt, -4pt), (5pt, 9pt), (-7pt, 5pt))
#for degree in range(0, 360, step: 11) {
  let angle = degree * 1deg
  let r = polygon-radius(points, angle)
  assert(r > 0pt)
  assert(length-close(r, polygon-radius(points.rev(), angle)))
  assert(length-close(r, polygon-radius(points.map(p => typ.rotate-point(p, 31deg)), angle + 31deg)))
}

// Every port side/index and rotation stays on a circle. On a rectangular
// straight side the exact requested spacing and index order are preserved.
#let legs = (left: 3, right: 3, top: 3, bottom: 3)
#for side in legs.keys() {
  for index in range(3) {
    for angle in (0deg, 37deg, 90deg, 180deg) {
      let p = gate-port-on-outline(
        (kind: "circle", radius: 10pt), legs, side, index,
        rotate: angle, port-spacing: 4pt,
      ).map(v => v / 1pt)
      assert(close(p.at(0) * p.at(0) + p.at(1) * p.at(1), 100))
    }
    let p = gate-port-on-outline(
      (kind: "rect", half-width: 10pt, half-height: 8pt, radius: 0pt),
      legs, side, index, port-spacing: 4pt,
    )
    let expected = if side == "left" { (-10pt, (index - 1) * 4pt) }
      else if side == "right" { (10pt, (index - 1) * 4pt) }
      else if side == "top" { ((index - 1) * 4pt, 8pt) }
      else { ((index - 1) * 4pt, -8pt) }
    assert(p.zip(expected).all(pair => length-close(..pair)))
  }
}
