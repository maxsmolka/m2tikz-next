# M6.7 - Unsupported-object and partial-output hardening

## Baseline and scope

Started from clean public main `ff7f75920e66b1e8bb4b4d6f74e6b017aa7a27b7`
after M6.6 PR #10, head `19ea4d23db87acaee85c6b35ff3d7db829452acf`,
passed all three required jobs in run 35011606155, merged and its milestone
branch was removed locally/remotely. This phase uses
`m6.7/unsupported-object-hardening`; latest release remains 0.5.0.

The classification contract is in [UNSUPPORTED_POLICY.md](docs/UNSUPPORTED_POLICY.md):
supported, explicitly limited presentation, unsupported with diagnostics, or
ignored only with positive evidence of nonsemantic runtime bookkeeping.
No unknown object is accepted by silently omitting it. No reduction, whole-
figure rasterization, legacy fallback, new public option or release is added.

## Traversal, ownership and diagnostics

- Complete figure/axes child traversal includes hidden handles. Primitive
  datatips/unknown children, active brushing, unknown groups/panels/annotations
  and unrepresented semantic properties fail analysis before product creation.
- A matching colorbar/legend watcher tag alone cannot hide text. Empty hidden
  runtime watchers need ownership/callback evidence. Known compound text with
  content fails rather than disappearing. Invisible semantic labels stay absent.
- Legends follow actual native/Octave object links, including subsets/reorder,
  not guessed label order. A uniquely owned boxplot child can link its compound.
- Colorbars retain actual ticks/labels/direction and require matching owner
  limits. Octave's stale separate Limits property is not treated as the display.
  Unknown axes-backed decoration children and modified colorbar images fail.
- Bar, boxplot, errorbar and gnuplot scatter compounds validate child geometry,
  roles, visibility and styles against their semantic/runtime signatures.
  Unknown/extra or edited children cannot be silently replaced by stale parent
  values. Group visibility is respected in recognized 3-D compounds.
- All native 3-D readers now enforce the automatic orthographic camera and
  explicit multi-object child-order contract. Unresolved depth scenes fail.
- Scalar logarithmic mapping that is not represented fails; one-row/column
  scalar vector images fail render planning before output preparation. Explicit
  hybrid still preserves the source pixel dimensions; auto is not a fallback.

Central property guards reuse existing diagnostic codes. Deterministic first-
failure traversal, code identity and unchanged source/products are tested;
exhaustive diagnostics and exact message wording are not promised.

## Correctness fixes found during the audit

The previous grouped-bar formula did not reproduce native Octave spacing and
width. Optional BarIR `xBounds` now carries verified native rectangle limits.
Validation rejects malformed bounds; old documents without the field retain
their established geometry, and JSON replay preserves the new limits.

The previous unfilled renderer background could make opaque overlapping axes
transparent. Optional AxesIR `background` distinguishes supported white and
transparent backgrounds; dual-Y helper layers explicitly remain transparent.
Missing fields retain older portable IR behavior. Arbitrary nonwhite axes and
transparent axes on nonwhite canvases fail rather than potentially hiding
scientific marks. Dark-theme defaults therefore need explicit supported source
styling by the caller; the exporter never changes source colors to pass a gate.

Octave gnuplot compounds have observed display limitations for large per-point
marker sizes/RGB. The reader verifies their known partition but retains full
authoritative parent sizes/RGB in IR. It does not copy display quantization into
scientific export data. This is distinct from accepting arbitrary edited patches.

## Compatibility and documentation

Public signatures/options remain unchanged. FigureIR remains version 2 with
optional additive fields; M7.1 will formalize the full compatibility policy.
Stricter failures close previously unguarded paths rather than promise broad
new object coverage. Existing presentation limitations, including automatic
ticks/font layout, normalized error-cap styling and non-pixel-identical 3-D
viewport sizing, are documented separately from scientific data preservation.

An obsolete M5.4 scatter3 rejection is updated to the bounded M6.5 support
contract. Existing multi-object test fixtures explicitly request child order;
new negative cases prove unresolved depth scenes still fail. The native dual-Y
workflow fixture now selects a white axes background explicitly.

Status, roadmap, changelog, architecture, support/runtime differences,
validation matrix, diagnostics and test documentation are aligned. Historical
reports are evidence of their own milestones, not rewritten support claims.

## Validation evidence

Validated with MATLAB R2026a Update 4 on Windows.

That historical statement remains unchanged. New native evidence below uses
MATLAB R2026a Update 5 on Windows; compiler evidence uses real Linux LuaLaTeX
1.22 / TeX Live 2025/Debian through a temporary compiler bridge, not a claimed
native Windows TeX installation.

| Layer | Evidence |
| --- | --- |
| Native MATLAB capability matrix | 50/50, repeated diagnostics/source state and existing-product sentinel checks |
| Native Octave 11.3 capability matrix | 52/52, including tampered compounds, decoration children and large scatter partition checks |
| Native MATLAB prior-family regression | 211/211: bars 30, boxplots 29, surfaces 23, rich scatter 29, images 26, tiled layouts 28, dual Y 20, scientific 3-D 26 |
| Focused real public exports | Nine MATLAB and nine Octave TeX/PDF workflows, with no mocked compiler |
| Additional native dual-Y workflow | 4/4: 85/170 mm colorbar profiles and repeated figure-set manifests |
| Full portable regression | Final complete pass after all reader, compound and opaque-background corrections |
| Visual review | All nine MATLAB source/export pairs, Octave grouped bars, final opaque/transparent overlays and 85/170 mm dual-Y layers inspected successfully |
| Static gates | Six architecture invariants, documentation links, whitespace, actionlint, staged confidentiality and citation 0.5.0 passed |

The portable baseline contains 140 core cases, 235 extended cases (two new bar
IR tests), eight curated PDFs, nine rich-scatter and eleven rich-image TeX
fixtures, plus accumulated security/layout/dual-Y/3-D/large-data foundation
suites and this milestone's matrix/workflows. Native and portable counts are
not combined into a runtime support claim. White test styling is explicit;
compiler success is not substituted for semantic/visual inspection.

## Acceptance decision

All local focused, full portable, native, visual and static gates passed on the
final implementation. Native export TeX is byte-identical to the nine reviewed
source/PDF fixtures. Exact-head hosted CI is still required before merge. Required jobs remain
`repository-policy`, `octave-tests`, and `tex-preview`, with no weakened gate.
No M6.8 work begins before merge, fast-forward verification and branch cleanup.
