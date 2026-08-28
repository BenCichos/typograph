# Core review and simplification — 2026-08-28

## Outcome and scope

Reviewed all 13 core source modules for correctness, duplication, unnecessary
special cases, validation, performance, and test coverage, following the
codereview checklist. Implemented the changes below and checked both themes
as public-API consumers. No theme source changes, version changes, publication,
or deployment were needed.

The baseline was the **existing working tree**, including the completed
relative-positioning feature and earlier fixes, not Git HEAD. Its source and
tests were copied before editing. Unrelated working-tree changes were preserved.
Core remains 0.2.2; both themes remain 0.1.0.

The runtime source went from 5,283 to 5,140 lines: **143 fewer lines**, including
comments and whitespace. That is a size observation, not a correctness metric.

## Findings and implemented changes

### [P2, fixed] Repeated offsets exhausted Typst's call stack

Location: [position.typ:137](../src/position.typ), `offset-point` and `offset`.

Each new offset nested the complete previous expression. A valid loop of 240
successive calls failed with `maximum function call depth exceeded` while
packing captures, even for a plain coordinate pair:

```typ
let point = (2, 3)
for _ in range(240) { point = typ.offset(point, 0.125, -0.25) }
typ.box(point)
```

Successive offsets now combine their numeric deltas. Capture bundles retain
their source nodes while only their root point is shifted. This keeps repeated
offset composition at constant expression depth; it does not flatten arbitrary
user-built expression trees. Zero offsets remain explicit points, so edge
clipping semantics are unchanged.

The new public-import regression covers coordinate pairs, named references,
nodes, and ports, with exact final positions and nontrivial grouped transforms.

### [P2, improved] Shared coordinate captures were imported twice

Location: [position.typ:48](../src/position.typ), `pack-captures`.

Node x/y fields commonly project the same captured point. Previously, each
axis separately imported and rebased the entire node table. Profiling the
101-node captured chain identified capture interning as the dominant cost.

Pair handling now recognizes complementary projections and imports the table
once, rebuilding both axes from that result. Nodes and point pairs use this
same handling; transforms share the same projection-recognition helper.
Different points per axis still take independent paths.

The final captured-chain workload takes about **41% less wall time and 26%
less peak resident memory**. See the complete measurements below rather than
extrapolating that improvement to all diagrams.

### [P3, simplified] Duplicate clipping algorithms

Location: [diagram.typ:546](../src/diagram.typ), `outline-crossing`.

Forward and reverse searches duplicated sampling, containment tests, physical
tolerance selection, and bisection. They now share one traversal, with reversed
segment/parameter order. Bisection tracks an inside and outside endpoint rather
than assuming ascending parameters.

New reversal properties cover lines, quadratics, cubics, stationary segments,
circles, ellipses, rounded rectangles, and concave polygons. Existing clipping
and rendering snapshots remain unchanged. Bounded curve sampling is retained;
this refactor is not a new exact curve-intersection solver.

### [P3, simplified] Repeated sizing, label, and scaling rules

Locations: [node.typ:340](../src/node.typ), [node.typ:707](../src/node.typ),
[node.typ:764](../src/node.typ), [geometry.typ:23](../src/geometry.typ).

- Standalone and composite outlines now use the same silhouette/label bounds
  calculation. The public extent helper also reuses the existing simple helper.
- Circle, ellipse, and rectangle drawing share label-overlay handling.
  The unused private `include-label` switch was removed; an empty label already
  expresses that case. Polygon rendering keeps its required local frame.
- Insets, radii, mark lengths, and part overrides share `scale-length`.
  Absolute components scale; percentages do not. Contextual length resolution
  and validation still occur before scaling.
- Removed unused imports and an unused private validation option.

Tests cover shifted labels, simple/composite bound equivalence, native shape
frames, percentages, mixed lengths, contextual em sizes, and transformed parts.

### [P3, simplified] Duplicate collection work and redundant inputs

Locations: [position-layout.typ:78](../src/position-layout.typ),
[diagram.typ:955](../src/diagram.typ).

Capture normalization already interns nodes into an indexed table. Outline
preparation no longer deduplicates that table again. Numeric-only preparation
uses direct node values in its buckets instead of an unused node/index wrapper,
and a plain loop instead of a cursor over a queue that never grows.

Numeric layouts skip the position resolver call entirely. The resolver reads
normalized work from its collection instead of also receiving an obsolete
copy. Duplicate names are validated once during preparation, not again during
drawing. Edges known to have no deferred endpoints skip the deferred-waypoint
scan.

Exact value equality remains authoritative. A new collision test verifies
that differing custom closures survive even when their identity keys and final
coordinates coincide.

### [P3, corrected] Performance documentation overstated CI guarantees

Location: [Performance Model](quarto/dev/performance.qmd).

Stress compilation did not enforce a runtime threshold, so it could not detect
a slowdown merely by succeeding. The documentation now distinguishes correctness
fixtures from repeated benchmarks, records construction costs separately from
dependency resolution, and removes unmeasured claims about hypothetical bounds
helpers.

## Measurements

Environment: Typst 0.15.1 (unknown commit), macOS 26.5.2, ARM64. Seven measured
fresh processes per workload/revision after one warmup, alternating revision
order, bundled fonts, no concurrent test/documentation builds. Measurements
include startup, compilation, rendering, and PDF export. OS caches were not
cleared. Peak RSS is measured per process and reported as a median, not as
retained memory or a leak measurement.

| Workload | Before (s) | After (s) | Before RSS (MiB) | After RSS (MiB) |
|---|---:|---:|---:|---:|
| grid | 0.282 | 0.281 | 67.8 | 67.6 |
| polygons | 0.309 | 0.309 | 52.4 | 51.8 |
| curves | 0.203 | 0.201 | 62.6 | 62.8 |
| ports | 0.205 | 0.204 | 67.3 | 67.4 |
| named-chain | 0.272 | 0.270 | 77.2 | 79.3 |
| captured-chain | 0.567 | 0.336 | 61.9 | 45.8 |
| grouped-axes | 0.497 | 0.483 | 98.3 | 79.8 |

Workload definitions are in [benchmark.typ](../tests/benchmark.typ) and the
three existing stress files. Raw per-run samples, ranges, and environment data
are in [benchmarks-2026-08-28.json](benchmarks-2026-08-28.json).

Outside the captured chain, wall times broadly overlap the observed ranges.
Grouped-axis peak memory decreased about 19%; named-chain peak memory
increased about 3% (roughly 2 MiB). These are workload-specific observations,
not guarantees or statistical significance claims.

Reproduce from the repository root:

```sh
python3 tests/benchmark.py --runs 7 --output /tmp/typograph-benchmarks.json
python3 tests/benchmark.py --root before=/path/to/baseline --root after=. --runs 7
```

Use identical fixture files in both roots. The recorded baseline is at
`/private/tmp/typograph-simplify.e2V1FM/before` for this local session. The
harness has bounded compiles, process-group cleanup on timeout, diagnostics
on failure, optional memory probes, and unit tests. It does not set a noisy
wall-clock CI pass/fail threshold.

### Experiment discarded

More detailed identity keys serialized normalized coordinates to reduce
equality scans. In the grouped-axis probe this increased runtime; with shared
capture imports it measured roughly 0.58s versus the baseline's 0.49s. Removing
those keys brought the probe to roughly 0.46s versus 0.48s. The more selective
keys were discarded. Final code retains the original cheap keys and exact
equality; fewer comparisons did not offset serialization/memoization costs.

## Audit coverage and remaining boundaries

- **Constructors and facade:** checked overload parsing, positional labels,
  partial application, extra arguments, and theme factories. Kept separate
  flippable/non-flippable signatures: merging them would broaden accepted
  arguments or require a new dynamic validation layer.
- **Positions and groups:** checked captures, forward/global names, per-axis
  cycles, mixed axes, source identity, offsets, and local-frame transforms.
  Rebasing for partial-axis rotation is necessary; replacing it with ordinary
  point rotation would change behavior for upright non-square gates.
- **Shapes and geometry:** checked degenerate outlines, polygon validation,
  port projection, parts, labels, and boundary calculations. Existing
  self-intersecting-polygon restrictions and bounded curve sampling remain.
- **Edges and renderer:** checked path construction, clipping, highlights,
  labels, stroke outsets, drawing order, bounds, and the numeric fast path.
  Retained the inline whole-diagram bounds accumulator; no replacement was
  benchmarked in this review.
- **Styles, themes, and config:** checked precedence, contextual em resolution,
  percentages, validation, nested scope restoration, and the neutral-core
  boundary. Existing context-sensitive measurement caveats remain documented.
- **Security/resource surface:** core contains no shell execution, network
  client, authentication, or authorization subsystem. This review found no
  new security issue in that surface. Custom builders and content are Typst
  code, not sanitized untrusted data; malformed hand-built internal records
  are not a hardened interchange format. Huge diagrams, arbitrary expression
  trees, and custom builders can still consume substantial compiler resources.
  The benchmark timeout is a harness safeguard, not a package resource quota.

No new unresolved correctness finding was established beyond the fixed
offset-composition failure. This is a source review with deterministic tests,
not exhaustive fuzzing or a proof of correctness.

## Verification

- Core: 29 positive Typst fixtures, 145 expected-diagnostic negative fixtures,
  12 Python helper tests, one outline snapshot, and seven SVG fixtures.
- Circuit: seven positive and 20 negative fixtures.
- ZX: ten positive and five negative fixtures, one outline snapshot, two SVG
  fixtures, and documentation asset-link checks.
- Existing snapshots were retained, not regenerated to accept output drift.
- All three documentation sites build: 28 HTML pages and 2,215 local/cross-site
  links checked, with zero failures. Shell syntax and Git whitespace checks pass.
