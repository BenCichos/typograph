# Theme compatibility review — 2026-08-28

## Outcome and scope

Core `typograph` is now `0.2.2`. Both `typograph-circuit` and `typograph-zx`
import `@preview/typograph:0.2.2`; their own package versions remain `0.1.0`.
Active examples, documentation, package tests, and local package staging
use the new core version. The existing core implementation changes from
the [previous review](review-2026-08-27.md) were preserved.

Reviewed both themes' complete source modules, manifests, test runners,
existing fixtures, READMEs, documentation pages, and workflows against the
core public API. The codereview checklist guided correctness, validation,
maintainability, security, and performance checks. The confirmed issues
below are fixed; no additional semantic defect was confirmed in ZX's thin
constructor wrappers.

## Findings and fixes

### Circuit marker sizing rejected valid font-relative lengths

Location: `typograph-circuit/src/lib.typ:22`, `_marker-size` and marker
constructors.

The old helper compared a length with `0pt` outside layout context. Valid
mixed lengths such as `1em - 2pt` could therefore fail before rendering.
Markers now forward a scalar size to the core gate, which resolves context
and validates the result at its existing layout boundary. They accept
`auto` or a non-negative length, including a zero minimum; size pairs remain
invalid. A minimum does not prevent labels or insets from enlarging a node.

Coverage: `constructor-contract.typ` checks all marker constructors with
absolute, zero, font-relative, and mixed lengths, including zoom behavior.
Four negative fixtures cover wrong types, pairs, absolute negative sizes,
and mixed lengths that resolve below zero.

### Circuit state/effect ports could rotate away from the flat side

Location: `typograph-circuit/src/lib.typ:33`, `_flat-side-gate`.

The constructors restricted port sides and flipping, but did not prevent
rotation from moving the flat edge away from those ports. Direct nonzero
rotation now produces a specific diagnostic. Both the required flip and
zero rotation are pinned in the constructor style, so lower-precedence
theme or diagram overrides cannot invalidate the orientation contract.
For rotated terminals, use a custom kind with the generic core gate API.

Coverage: constructor contracts check actual flat-side geometry under
conflicting lower-precedence overrides. Negative fixtures check both
state/effect flips and rotations, tip-side ports, and malformed inputs.

### Circuit semantic levels were validated only when used

Location: `typograph-circuit/src/lib.typ:429`, `circuit`.

The helper now validates every supplied semantic y-level as an integer or
float before calling the body, even if that level is unused. The body
contract is documented as a diagram-item array or `none`, supplied directly
or returned by a callback. Arbitrary Typst content is not a diagram body.

Coverage: all four invalid level arguments, invalid direct/callback bodies,
valid callbacks and empty bodies, option forwarding, and shared config
inheritance/overrides.

### Theme documentation contained non-executable examples and stale claims

Locations: circuit `docs/quarto/extending.qmd`, `constructors.qmd`, and
`circuit-helper.qmd`; ZX `docs/quarto/constructors.qmd`, `extending.qmd`,
`theme.qmd`, and `README.md`.

- Circuit's extension example accessed the nonexistent `node-defaults`
  field. It now uses the supported theme schema.
- Circuit's constructor guide now describes scalar marker minima,
  font-relative sizes, fixed terminal orientation, the separate `control`
  kind, and the right-only vacuum/Fock-state defaults.
- ZX's extension example now accesses `zx.theme.node-presets.z` instead of
  the undefined `classic.node-presets.z`.
- ZX's faulty wire is documented as solid orange, matching the preset.
  Links to core documentation use published `.html` pages with valid
  anchors. Palette documentation explains that changing palette entries
  does not retroactively alter preset values.
- READMEs describe local core-version requirements and the expanded tests;
  ZX's image paragraph markup was corrected.

Both themes now compile complete extension examples as documentation
contracts and verify that extending a theme leaves its original data intact.

### ZX documentation assets were stale and duplicated

Locations: `typograph-zx/docs/img/`, `docs/quarto/img`, and `tests/run.sh:84`.

Regenerated both canonical SVGs with Typst 0.15.1 and system fonts disabled.
The site now uses `docs/quarto/img -> ../img`, sharing the README's canonical
sources and images. The runner checks both generated SVGs and site/canonical
consistency, so replacing the symlink with stale copies will fail tests.
The outline probe now exercises actual semantic constructors, including
the effect's default mirror; the expected geometry snapshot is unchanged.

The redundant site image directory was moved, not irreversibly deleted.
Its recovery copy is at
`/private/tmp/typograph-theme-review.bnE0cm/zx-quarto-img-before-link`.
Temporary backups are not a substitute for version control.

### Negative-fixture registration could hide missing expectations

Location: `typograph-circuit/tests/run.sh:27`.

The runner now resolves expected diagnostics through a function and fails
explicitly for an unregistered fixture instead of reusing a previous loop
iteration's expectation. ZX's new negative-test section follows the same
pattern. Both runners check the intended error message, not merely failure.

## Verification

All checks below passed locally with Typst 0.15.1 and Quarto 1.10.18.

| Package | Positive Typst fixtures | Negative fixtures | Additional checks |
| --- | ---: | ---: | --- |
| typograph | 25 | 123 | 9 Python tests, 1 outline snapshot, 6 SVGs |
| typograph-circuit | 6 | 20 | All constructors, compositions, wrapper/config and documentation contracts |
| typograph-zx | 9 | 5 | 1 outline snapshot, 2 SVGs, site/canonical asset consistency |

- All three `bash tests/run.sh` suites and shell syntax checks pass.
- All three Quarto sites build: 19 core, 5 circuit, and 4 ZX pages.
- Checked 2,148 local/cross-site file and anchor references across the
  28 generated HTML pages: no broken targets.
- Compiled both themes together in one document against core `0.2.2`,
  checking shared config inheritance and explicit scale overrides.
- Visually inspected both regenerated ZX figures and circuit constructor
  and smoke renderings, including flat-side multiports and marker sizing.
- Core `git diff --check` passes.

No authentication, network service, or database surface is introduced by
these packages; no actionable security finding or new unbounded runtime
work was identified in this review. This is not an exhaustive fuzzing or
performance audit. Hosted CI, external websites, other operating systems,
and a published package-registry installation were not tested. Changes are
local only: no commit, tag, package publication, or deployment was made.
