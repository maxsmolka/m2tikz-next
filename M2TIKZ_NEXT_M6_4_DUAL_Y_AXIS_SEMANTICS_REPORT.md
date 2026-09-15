# M6.4 Dual Y-Axis Semantics

## Baseline and scope

Baseline: public main `cdc33d1caec42f3457b024612c7b87dc6b66fa4d`, with M6.3
merged and its milestone branch removed. The starting working tree was clean.
Latest released version remains 0.5.0; this phase creates no release or tag.

Implement the bounded native MATLAB `yyaxis` line/scatter contract, with
explicit scientific ownership rather than rescaling right-side data into a
left-side coordinate system. Public signatures/options/results are unchanged.

## Architecture

- Documented active-side `Children` membership is compared with `allchild`.
  Cleanup restores the initially active side on success and failure. Native
  allchild order is side-grouped, not assumed to equal global creation order.
- Optional FigureIR v2 `dualY` metadata preserves right limits, scale,
  direction, ticks, label and color plus left ruler color. Existing Y fields
  remain left-owned; every dual-axis series requires explicit `yAxis`.
- Native legend links resolve selection/reordering without label matching or
  positional ownership guesses. Missing/ambiguous links are unsupported.
- The handle-free renderer decorates coincident left/right coordinate systems,
  renders each scientific table once in IR order, then draws the linked legend.
  Transparent axes preserve paint order without changing coordinates.
- Shared X and ColorMappingIR remain singular. Colorbars and one tiled cell
  still belong to one axes. Single/tiled publication profiles reserve right
  ruler gutters; east colorbars have a fixed 8 pt body and separate tick space.
- Invalid membership/state/shared-X conditions have structured E059/E060/E061
  diagnostics. Invalid IR/log domains and unsupported profile geometry fail
  before scientific products are written. No legacy or whole-figure fallback.

See [ADR-0023](docs/adr/ADR-0023-dual-y-axis-semantics.md) and the complete
[bounded contract](docs/DUAL_Y_AXES.md).

## Native MATLAB evidence

Validated with MATLAB R2026a Update 4 on Windows.

That exact sentence records the historical broad evidence. This phase has
separate native MATLAB R2026a Update 5 on Windows evidence; it does not replace
the historical matrix or claim additional versions/platforms.

- `runM64DualYMatlabTests`: 20 reader, lifecycle, legend, independent
  ticks/scales/directions, mapped scatter/colorbar, tiled/profile and negative
  cases. Negative cases check failure, no successful TeX output and no mutation.
- `runM64DualYWorkflowTests`: four real public workflow cases: 85/170 mm with
  a logarithmic right axis/colorbar, figure-set export and repeat manifest bytes.
  MATLAB used a temporary PATH bridge to real Linux LuaLaTeX, not a mock and
  not a claim of native Windows TeX availability.
- The portable dual-Y suite is also exercised under native MATLAB.

The final geometry/renderer state passed all 20 native dual-Y cases, all 16
portable cases under MATLAB, and all four native workflows. Prior-feature
native regression also passed: 29 rich-scatter cases, 26 rich-image cases and
28 tiled-layout cases. The combined session stalled in MATLAB graphics
handshaking during the tiled suite; that incomplete run was not counted.
A fresh isolated MATLAB session completed all 28 tiled cases successfully.

## Portable and compiler evidence

- GNU Octave 11.3 runs 16 handle-free dual-Y IR/JSON/order/profile/negative
  cases. This is not native Octave yyaxis evidence.
- Six focused portable TeX fixtures cover linear/independent-log coordinate
  systems, both profile widths and scatter-role isolation.
- Thirteen native-generated TeX fixtures exercise reordered legends, ticks,
  scale/direction combinations, tiled ownership and 85/170 mm geometry.
  All thirteen plus the six portable fixtures compiled after the last change.
- The required full regression includes 140 core cases/eight curated PDFs,
  the established 233 extended portable cases, nine rich-scatter and eleven
  rich-image compilations, plus S1 and M6.3 foundation suites.
- Compiler evidence uses Linux TeX Live 2025/Debian, LuaTeX 1.22 and PGFPlots
  compatibility 1.18. It is separate from historical TeX Live 2026 evidence.

## Visual findings and corrections

Native-generated and portable PDFs were rasterized with Poppler and inspected.
This is developmental visual inspection, not a pixel-identical native golden
comparison or a guarantee for arbitrary text lengths and grid densities.

The first review exposed inherited scatter marker-role leakage: PGFPlots cycle
styles introduced blue borders even when the normalized edge was absent, and
filled marker primitives still stroked `draw=none`. The shared scatter renderer
now uses explicit non-cycling plot styles and zero draw/fill opacity only for
roles explicitly marked absent. Source alpha support was not broadened.
The new scatter-role fixture covers filled mapped/RGB points and unfilled
data-colored outlines; this is a required correctness dependency of M6.4.
The [PGFPlots manual](https://tikz.dev/pgfplots/reference-addplot) describes
the cycle-list difference between explicit plot options and the `+` variant.

A second review found insufficient east-colorbar tick space at 170 mm. The
profile now reserves a fixed body and independent physical gutters at both
widths. A portable geometry assertion guards the boundary. Source-size layout
is untouched, and too-dense publication layouts fail explicitly.
Final reviewed native 85/170 mm colorbar and tiled views have readable labels;
the 85 mm workflow PDF has a measured width of 240.945 PDF points (85 mm).

## Documentation and boundaries

Added the dual-axis contract and ADR; updated architecture, status, roadmap,
README, support/workflow/profiles, tiled interaction, diagnostics, runtime
evidence and test documentation. Also corrected the current upstream-divergence
summary, which still listed now-supported rich scatter and layouts as gaps.
Historical reports/release notes remain historical. CITATION.cff remains 0.5.0.

Unsupported cases include non-line/scatter children, ambiguous hidden
membership, unsupported ruler presentation, manual aspect ratios, nonnumeric X,
unrelated overlays and multiple manual dual axes in the publication transform.
Scientific data, color/size metadata and ownership are never silently reduced.

## Security and integration

The confidentiality boundary, output-product checks, no-shell-escape compiler
policy and required three hosted jobs remain intact. No credentials, private
paths/history or local runtime bridge are included in the public tree. Only
this milestone branch may be pushed. Merge requires green `repository-policy`,
`octave-tests` and `tex-preview` on the exact PR head, followed by cleanup.

## Acceptance decision

Final local acceptance passed on 2026-09-15: 140 core cases/eight curated
compilations, all 233 established extended cases, nine rich-scatter and eleven
rich-image compilations, S1's 18 portable path and three compiler cases,
M6.3's 15 portable and four compiler cases, and M6.4's 16 portable/six compiler
cases. Native and visual evidence is recorded separately above.

All six architecture invariants, documentation links, confidentiality,
citation metadata (still 0.5.0), actionlint and whitespace checks passed.
Local acceptance is complete; hosted integration must still require the three
green jobs on the exact PR head. M6.5 may start only after merge verification
and local/remote milestone branch cleanup. This report alone is not a claim
that hosted checks or merge have already occurred.
