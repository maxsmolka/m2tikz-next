# m2tikz-next M4.1 MATLAB validation report

## Executive Summary

The existing M4.0 validation harness completed against a real MATLAB runtime.
The first unmodified run failed all 26 modern fixtures at the reader boundary;
the final run passes F01-F26, all L0-L11 layers, the modern public workflow,
the selected legacy smoke, and the V01-V08 visual review. Fixes were derived
from captured HG2 and byte-level evidence and contain no release, OS, or
graphics-toolkit branch.

The MATLAB claim is locally justified. Completion remains conditional because
the branch has not been pushed and hosted GNU Octave 11.3 Linux CI therefore
has not exercised this diff.

## MATLAB Runtime

- Version: `26.1.0.3312084 (R2026a) Update 4`
- Release: `2026a`
- Architecture: `win64`
- Operating system: Windows
- Invocation: noninteractive `matlab -batch`

No license identifier, account information, hostname, home path, or machine ID
was retained. The runtime displayed a trial-use banner; that banner is not part
of the evidence report.

## Initial Unmodified Run

The exact first command was:

```powershell
matlab -batch "addpath('test'); result=runMatlabValidation; assert(result.success)"
```

It completed the harness with 0/26 fixtures passing, 26/26 failing, zero
environment failures, zero semantic mismatches, and a passing separate legacy
smoke. Every fixture stopped at the same reader error:

```text
M2T2:E001:UnsupportedObject
type=annotationpane
path=figure.children{...}
```

The console result, `report.json`, `report.md`, HG snapshots, fixture outcomes,
and failure classifications were preserved under the ignored
`.audit/m41-initial-matlab` evidence directory before product changes.

## Environment

The initial L0 environment layer passed. MATLAB could write output and temp
files; LuaLaTeX, PGFPlots, PNG writing, and Poppler geometry inspection were
available. There were no environment-only failures in F01-F26.

A later ad hoc M3 suite and one fresh-process determinism attempt without an
explicit TeX lane selected a separate MiKTeX installation and reported
`luaotfload ... no writeable cache path`. Repeating with the validated TeX Live
2026 executable and a writable cache passed. This was classified ENV and
caused no product change.

## Failure Triage

| Fixtures | Layer/category | Disposition | Observation and semantic impact | Minimal response |
| --- | --- | --- | --- | --- |
| F01-F26 | L1 / READER | A | MATLAB creates a direct figure child `AnnotationPane`, Type `annotationpane`, Tag `scribeOverlay`, hidden from handle discovery and empty; reader rejected it before scientific content | Ignore only an empty, figure-owned pane with the exact runtime-decoration signature |
| Focused reader rerun | IR | A | `Axes.Box` is `matlab.lang.OnOffSwitchState`; FigureIR requires a text enum | Normalize the supported on/off value to lower-case character text |
| F25-F26 repeat evidence | RENDER/determinism | C | MATLAB `imwrite` adds a PNG `tIME` chunk; pixels, alpha, dimensions, and IDAT are identical but bytes vary by wall clock | Remove only the optional `tIME` chunk after encoding |
| M3.2 numeric handle fixture | READER | A | A valid figure stored in a numeric legacy-handle array compared unequal to its HG2 Parent under class-strict `isequal` | Compare graphics identity with handle equality |
| Ad hoc TeX rerun | ENV | F | Nonvalidated MiKTeX cache was not writable | Select the already validated TeX Live installation and writable cache |

There were no disposition B semantic mismatches, D newly unsupported MATLAB
features, or E architecture failures.

## HG2 Audit Findings

Normalized, privacy-safe snapshots confirmed:

- line: `matlab.graphics.chart.primitive.Line`, axes-owned;
- scatter: `matlab.graphics.chart.primitive.Scatter`, Type `scatter`;
- errorbar: `matlab.graphics.chart.primitive.ErrorBar`, Type `errorbar`;
- legend: `matlab.graphics.illustration.Legend`, figure child with axes owner;
- colorbar: `matlab.graphics.illustration.ColorBar`, figure child with axes owner;
- image: `matlab.graphics.primitive.Image`, scaled scalar CData with XData,
  YData, and AlphaData;
- helper: `matlab.graphics.shape.internal.AnnotationPane`, Type
  `annotationpane`, Tag `scribeOverlay`, HandleVisibility off, figure-owned,
  and empty in supported fixtures;
- axes, labels, title, multiple-axes positions, custom CLim, custom colormap,
  `axis xy`, reversed YDir, and manual placements expose the semantic
  properties expected by the existing IR.

Scatter, errorbar, legend, colorbar, and image data required no MATLAB-only IR.

## Reader Compatibility Changes

### MATLAB-READER-001: figure scribe overlay and on/off value

- Evidence: all initial fixtures exposed the empty `scribeOverlay`; focused
  rerun then exposed an OnOffSwitchState at `Axes.Box`.
- Root cause: a runtime implementation child was treated as content, and a
  semantic on/off value was assigned without text normalization.
- Change: require exact type, tag, handle visibility, figure ownership, and
  empty children before excluding the pane; normalize `Box` with `char` and
  lower case.
- Test: empty pane succeeds; a user textbox makes the pane nonempty and still
  raises E001; plain/tex/latex text semantics remain intact.
- Octave regression: M2-M2.3 and image readers pass.

### MATLAB-READER-002: graphics-handle identity

- Evidence: a valid figure stored in a numeric handle array passed `ishandle`
  but its HG2 Parent failed class-strict equality.
- Root cause: identity was compared as MATLAB values rather than graphics
  handles.
- Change: use scalar graphics-handle equality, with `isequal` only as fallback.
- Test: numeric legacy figure handle reads the same line IR.
- Octave regression: reader and figure-set suites pass.

The M2/M2.2 portability fixtures were also made capability-aware: they create
or remove Octave-specific legend appdata only when that appdata exists. They do
not weaken reader behavior or synthesize unsupported MATLAB ownership.

## IR Comparison

The MATLAB and Octave normalized IR files were compared for all supported
fixtures. Scientific data, kinds and order, text, image matrices, coordinates,
explicit CLim, and explicit colormaps are exact or numerically equivalent.

Overall fixture objects classify as `expected_runtime_difference` where they
contain runtime defaults: source size, default line colors, default colormap,
automatic limits, or placements derived from default axes/colorbar geometry.
F22's explicit colormap agrees; only source size differs. No true semantic
mismatch remains.

## Renderer Validation

The handle-free renderer remains runtime-, OS-, and toolkit-unaware. Its TeX
output passes deterministic repeat and LuaLaTeX compilation. The only renderer
compatibility change is generic PNG metadata normalization: parsing removes the
optional `tIME` chunk but leaves IHDR, IDAT, IEND, pixels, alpha, and dimensions
unchanged.

## Public Workflow

`m2t.export(...)` passes on MATLAB for line, scatter, errorbar, multiple axes,
colorbar, scalar heatmap, publication profile, vector, hybrid, and automatic
backends. Structured success/status, diagnostics, paths, profile metadata,
render metadata, compilation, and PDF validation all pass.

## Publication Profile

The full M3.1 profile suite passes. Single-column output measures 240.9 pt
(85 mm) and double-column output 481.9 pt (170 mm), each within 0.05 pt.
Typography, relative geometry, scientific content, and caller-figure state are
preserved. Profile transforms remain IR-only.

## Figure Sets

The full M3.2 suite passes in an isolated MATLAB evidence directory: multiple
entries, publication-profile defaults, per-entry double-column override,
`ContinueOnError` true/false, multiple axes, colorbar, deterministic manifest
and TeX, path handling, profile-none compatibility, and aggregate counts.
F24 also passes in the main harness.

## Image/Heatmap

F18-F22 and all M3.3 H1-H18 tests pass. Matrix shape/orientation, explicit
coordinates, normal/reversed YDir, CLim, custom colormap, colorbar ownership,
NaN cells, JSON replay, and deterministic TeX are preserved. RGB true-color,
semantically relevant AlphaData, and infinity remain precise unsupported
diagnostics; scope was not broadened.

## Hybrid Backend

F25 and all M3.4 R1-R24 tests pass. PNG dimensions, coordinate orientation,
CLim/colormap mapping, NaN transparency, deterministic assets, stale-asset
cleanup, paths with spaces, vector axes/text/colorbar, mixed line/image figures,
figure sets, and LuaLaTeX output are validated. PNGs are produced from
normalized matrix data, not screenshots.

## Backend Planner

F26 and all M3.5 P1-P24 tests pass. The exact decisions are:

| Visible scalar cells | Selection |
| --- | --- |
| 4095 | vector |
| 4096 | vector |
| 4097 | hybrid |
| 250 x 250 | hybrid |
| 500 x 500 | hybrid |

Equivalent normalized MATLAB and Octave inputs select the same backend. Explicit
vector/hybrid requests and unsupported RGB/alpha diagnostics remain unchanged.

## Determinism

Repeated exports in one MATLAB process produce identical normalized IR, TeX,
PNG, manifest, and planner decisions. A second fresh MATLAB batch process
passes 26/26 and matches selected first-process evidence byte-for-byte,
including reports, IR, TeX, manifest, and hybrid PNG. The identified PNG
nondeterminism was isolated to the optional `tIME` data and CRC before its
generic removal.

## Figure Lifecycle

F01-F26 lifecycle checks pass. Figure existence/visibility, limits, directions,
series data, CLim, colormap, source size, and current-figure behavior where
meaningful are preserved. Numeric legacy handles are accepted without mutating
their figures.

## TeX/PDF Validation

Supported outputs compile with LuaLaTeX/TeX Live 2026 and PGFPlots 1.18. PDFs
exist, are nonempty, and pass selected physical geometry checks. No MATLAB-only
TeX renderer or weakened compilation gate was introduced.

## Visual Review

Human review of rendered MATLAB/Octave PDF pairs passed:

- V01/F08: line order and legend entries;
- V02/F04: errorbar data and extents;
- V03/F13: two axes and relative layout;
- V04/F15: image orientation and colorbar range;
- V05/F18: scalar matrix orientation;
- V06/F22: explicit custom colormap;
- V07/F23: publication-profile curve and geometry;
- V08/F25: hybrid raster orientation, extrema, axes, and vector colorbar.

Visible differences are limited to classified runtime defaults such as source
page size, automatic limits, and default palettes. Pixel identity was not used
as a semantic criterion.

## Legacy Status

The separate `matlab2tikz(...)` smoke passes at L11. This is a smoke result,
not a claim that the entire historical legacy feature surface was revalidated.

## MATLAB/Octave Differences

Actual differences and their normalization are documented in
`docs/MATLAB_OCTAVE_DIFFERENCES.md`. MATLAB uses dedicated HG2 Scatter,
ErrorBar, Legend, ColorBar, Image, and AnnotationPane classes; Octave ownership
and compound-object representation can differ. Existing capability and
ownership logic normalizes supported semantics without raw-tree equality.

## Regression Results

Local evidence completed so far:

- initial complete GNU Octave/public-preview baseline: pass;
- MATLAB F01-F26: 26/26 pass, twice in fresh batch processes;
- MATLAB M2-M2.3 focused reader/renderer suites: pass after test-fixture
  portability corrections;
- MATLAB M3 workflow/compiler and M3.1: pass with the validated TeX Live lane;
- MATLAB M3.2: 16/16 pass;
- MATLAB M3.3: 18/18 pass;
- MATLAB M3.4: 24/24 pass;
- MATLAB M3.5: 24/24 pass;
- M4.1 focused compatibility regressions: pass;
- relevant Octave reader and figure-set reruns after each reader cluster: pass;
- visual V01-V08: pass;
- final exact-worktree public-preview validation, including M2-M2.3, TeX,
  architecture invariants, documentation links, citation, and legacy: pass;
- examples 06-10: pass; automatic selection reports small=`vector` and
  dense=`hybrid`;
- final fresh-process MATLAB comparison: reports, selected IR/TeX, F24
  manifest, and F25/F26 PNG evidence are byte-identical;
- `git diff --check`: pass;
- workflow diff: empty; local `actionlint` executable unavailable, so no claim
  of a new actionlint run is made.

## Hosted CI Status

The existing public hosted GNU Octave jobs were green before this local branch.
This branch is intentionally unpushed, so hosted Linux has not validated the
MATLAB compatibility diff. No licensed MATLAB requirement was added to public
CI. Hosted confirmation is a remaining release gate, not assumed evidence.

## Support Matrix

`docs/MATLAB_VALIDATION_MATRIX.md` records validated, partial, and unsupported
capabilities. The exact justified public statement is:

> Validated with MATLAB R2026a Update 4 on Windows.

It does not claim all MATLAB versions or operating systems.

## Remaining Limitations

- Hosted GNU Octave 11.3 Linux must run after review/push.
- A base-only MATLAB installation was not available. No optional toolbox API
  was observed, but "Validated with base MATLAB only" is not claimed.
- RGB/alpha images, arbitrary annotations, per-point scatter styling,
  `tiledlayout`, `yyaxis`, polar, and migrated 3-D rendering remain outside the
  supported modern scope.
- Shared figure-level elements retain partial runtime-reader coverage.

## Completion Questions

1. Initial unmodified MATLAB validation completed: **yes**, 0/26 pass.
2. Initial failure: all fixtures rejected the empty MATLAB `scribeOverlay`
   `annotationpane` at the reader boundary.
3. Environment-only failures: none in F01-F26; one later nonvalidated MiKTeX
   cache selection was ENV and resolved without code.
4. Product changes: narrow annotation-pane classification, OnOffSwitchState
   text normalization, graphics-handle identity, and PNG `tIME` normalization.
5. Capability-based rather than version-based: **yes**.
6. F01-F26 on MATLAB R2026a: **26/26 pass**.
7. Normalized scientific semantics equivalent to Octave: **yes where expected**;
   only documented runtime defaults differ.
8. Line/scatter/errorbar: **pass**.
9. Legends/colorbars: **pass**.
10. Multiple axes/layouts: **pass**.
11. Scalar images/heatmaps: **pass**.
12. Hybrid backend: **pass**.
13. Auto selects the same backend as Octave: **yes**.
14. Publication-profile physical dimensions: **yes**, 85 mm and 170 mm within test
    tolerance.
15. `exportSet`: **pass**.
16. Repeated MATLAB outputs deterministic: **yes**, same and fresh process.
17. Caller figures unmodified: **yes**.
18. LuaLaTeX outputs compile: **yes** with the validated TeX Live lane.
19. Visual subset: **pass**.
20. Legacy `matlab2tikz(...)`: **separate smoke pass**.
21. Toolbox beyond base MATLAB: **none observed in the modern call path; a
    base-only installation was not available to prove isolation**.
22. Octave regressions: **local relevant and initial full baselines green; final
    exact-worktree gate pending below**.
23. Hosted Linux after changes: **not yet run because the branch is unpushed**.
24. Exact support statement: **Validated with MATLAB R2026a Update 4 on
    Windows.**
25. Next step: **preview patch release preparation after final local gates and a
    green hosted Octave run**, rather than speculative M4 reader work.

## Recommendation

The evidence supports preparing `v0.2.1-preview.1` once the final exact-worktree
local regression and hosted GNU Octave Linux CI are green. No release tag,
commit, or push belongs to this M4.1 execution without separate authorization.

CONDITIONAL MATLAB R2026a VALIDATION
