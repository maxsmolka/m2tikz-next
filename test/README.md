# Testing m2tikz-next

The modern pipeline is validated separately at the runtime-reader, normalized
IR, renderer, workflow, compiler, and visual levels. Inherited matlab2tikz
tests are described at the end of this guide.

## Environment and evidence

Validated with MATLAB R2026a Update 4 on Windows.

This is the recorded MATLAB boundary. GNU Octave 11.3 is the hosted Linux CI
baseline. Native reader evidence applies to the runtime where it was collected;
portable IR/renderer fixtures cannot establish native graphics support.
TeX/PDF compilation and visual review provide additional, distinct evidence.
See [installation](../docs/INSTALLATION.md), the
[MATLAB matrix](../docs/MATLAB_VALIDATION_MATRIX.md), and
[runtime differences](../docs/MATLAB_OCTAVE_DIFFERENCES.md).

PowerShell 7, Git, Python, Octave, and latexmk are used by the public gate.
Workflow tests require LuaLaTeX, TikZ/PGFPlots and standalone; physical sizing
checks also need pdfinfo. Optional visual tools include Pillow and pdfplumber.
Historical TeX evidence uses TeX Live 2026 and PGFPlots 1.18.x.

## Public repository gate

From PowerShell at the repository root:

```powershell
./test/runPublicPreviewValidation.ps1
```

Use `-OctaveCommand`, `-LatexmkCommand`, and `-PythonCommand` for commands not
on PATH. Generated files default to ignored `.audit/public-preview`.
`-SkipCoreTests`, `-SkipTexCompilation`, and `-SkipRichExample` select partial
lanes; a partial pass is not a full acceptance result.

The gate runs M2-M2.3 reader/renderer suites plus M6.1 rich scatter and M6.2
rich images (140 current core cases), fixture generation, examples 01-05 and
11-12, and a separate legacy smoke export. It compiles eight curated documents
and checks selected architecture invariants, links, citation metadata,
publication safety, and whitespace. It does not run every extended suite.

GitHub Actions is the current hosted system. The required jobs are:

| Job | Coverage |
| --- | --- |
| repository-policy | Six architecture invariants, links, confidentiality, citation, actionlint, whitespace. |
| octave-tests | Core readers/renderers, fixtures, smoke generation, MATLAB-harness preparation, portable M5/tiled/dual-Y IR tests and S1 security cases. |
| tex-preview | Example compilation, workflow/compiler/profile tests, set/image/backend smoke tests, publication calibration, rich scatter/image TeX and set cases, S1, tiled-profile and dual-Y compiler cases. |

All three must pass before a milestone merge. The Octave image is digest-pinned
in [ci.yml](../.github/workflows/ci.yml). Licensed MATLAB validation is separate.

M6.4 adds `runM64DualYIrTests` (16 portable cases) and `runM64DualYTexTests`
(six real compilations). Native-only `runM64DualYMatlabTests` (20 cases) and
`runM64DualYWorkflowTests` (four public export/set cases, actual LuaLaTeX
required) establish the distinct Update 5 reader/workflow evidence. Generated
native TeX/PDFs additionally require visual review, not just a PDF header check.
See [the bounded contract](../docs/DUAL_Y_AXES.md).

M6.5 adds `runM65Scientific3DIrTests` (19 portable cases) and
`runM65Scientific3DTexTests` (seven compilations). Native-only
`runM65Scientific3DMatlabTests` (26 cases) and
`runM65Scientific3DWorkflowTests` (four public profile/set exports, real compiler)
exercise the [bounded 3-D contract](../docs/SCIENTIFIC_3D.md). Native reference
images and compiled PDFs must be reviewed for point colors, depth, projection
and wire connectivity. A successful compile alone is insufficient.

M6.6 adds `runM66LargeDataContractTests` and `runM66LargeDataTexTests`: ten
small representatives each, testing sample/table/pixel counts and real TeX
compilation without timing thresholds. Full native/IR measurements live in
`benchmarks/benchmarkModernLargeData.m`, separate from CI. See the
[large-data contract](../docs/LARGE_DATA.md) for exact stage/precision boundaries.

Both suites also run six `runM66ColorMappingTests` fixtures: discrete boundary
values, variable sizes, 3-D, surfaces, two/three-color and horizontal colorbars.
The compiler lane compiles all six. `runM66ColorMappingMatlabTests` adds four
native reference figures for scatter, scatter3, surface and scalar image;
compare their source PNGs to compiled PDFs, rather than treating compilation
or sample counts alone as proof of correct color semantics.

## Extended portable regression

The public gate provides M2-M2.3 core coverage. Run the additional workflow
and IR suites from an Octave session at the repository root:

```matlab
addpath('test');
runM3WorkflowTests(fullfile('.audit','extended','workflow'));
runM3CompilerTests(fullfile('.audit','extended','compiler'));
runM31ProfileTests(fullfile('.audit','extended','profile'));
runM32FigureSetTests(fullfile('.audit','extended','sets'));
runM33ImageTests(fullfile('.audit','extended','images'));
runM34HybridImageTests(fullfile('.audit','extended','hybrid'));
runM35BackendPlannerTests(fullfile('.audit','extended','planner'));
runM40MatlabPreparationTests(fullfile('.audit','extended','preparation'));
runM51AnnotationIrTests(fullfile('.audit','extended','annotation-ir'));
runM52GroupedBarIrTests(fullfile('.audit','extended','bar-ir'));
runM53BoxplotIrTests(fullfile('.audit','extended','boxplot-ir'));
runM54SurfaceIrTests(fullfile('.audit','extended','surface-ir'));
runPublicationProfileTests(fullfile('.audit','extended','publication'));
runM61RichScatterTests(fullfile('.audit','extended','scatter'));
runM62RichImageTests(fullfile('.audit','extended','rich-images'));
```

The recorded M6.2 result is 233/233 for this extended set. The public gate and
extended set overlap in rich scatter/image cases; their counts must not be
added as unique tests. Reader/renderer validation, serialization/replay,
unsupported diagnostics, source lifecycle, determinism, overwrite behavior,
relative assets, manifests, and physical sizing are checked separately.

Older complete M2 compile/geometry matrices are available through
`runM21Validation.ps1`, `runM22Validation.ps1`, and `runM23Validation.ps1`.
The M2.1 runner also invokes line-prototype validation.

## Rich scatter and image validation

`runM61RichScatterTests` covers 29 cases: constant/per-point size and color,
scalar colormap ownership, edge/face roles, legends, JSON compatibility,
lifecycle, determinism, negative controls, and a 10k-point render case.
`runM61RichScatterFigureSetTest` checks the mixed public workflow.

```powershell
./test/runM61RichScatterTexValidation.ps1
```

`runM62RichImageTests` covers 26 cases for RGB classes, image alpha, direct
scalar indices, old-v2 defaults, exact RGBA channels, deterministic assets,
planner reasons, source lifecycle, malformed-input diagnostics, and 512x512
planning. Scalar NaN is an explicit missing cell; RGB NaN and mapped alpha fail.
RGB/nonopaque alpha requires hybrid, while forced vector fails precisely.

```matlab
addpath('test');
runM62RichImageTexTests(fullfile('.audit','rich-image-tex'));
```

Eleven focused exports cover vector/hybrid scalar, RGB/alpha, overlays,
colorbars, 85/170 mm profiles, and a figure set. Compilation alone does not
prove correct alpha, orientation, colors, or placement; visual review is a
separate recorded acceptance step.

## Native MATLAB validation

The runtime/environment and F01-F26 harness is invoked with:

```console
matlab -batch "addpath('test'); runMatlabValidation"
```

`runM40MatlabPreparationTests` tests the harness without a licensed MATLAB
runtime and must not be presented as native MATLAB execution. Native focused
suites include `runM41MatlabCompatibilityTests`, `runM51AnnotationTests`,
`runM52GroupedBarTests`, `runM53BoxplotTests`, `runM54SurfaceTests`, and the
M6.1/M6.2 suites above. Evidence must record the actual runtime/update.

Portable annotation, boxplot and 3-D IR tests do not establish native Octave
support for the corresponding MATLAB compound objects. The grouped-bar IR
suite additionally tests native Octave recognition. Optional toolbox/package
availability must be reported explicitly, not hidden by a broad support claim.

## Architecture and publication checks

```powershell
./test/checkRendererInvariant.ps1
./test/checkProfileInvariant.ps1
./test/checkFigureSetInvariant.ps1
./test/checkHybridInvariant.ps1
./test/checkPlannerInvariant.ps1
./test/checkMatlabValidationInvariant.ps1
./test/checkDocumentationLinks.ps1
./test/checkConfidentiality.ps1
python ./test/validateCitation.py ./CITATION.cff
git diff --check
```

The confidentiality check scans tracked files; newly added documents must also
be checked before publication. CI validates YAML with actionlint. Keep generated
logs, PDFs, PNGs and reports under ignored `.audit/` paths; only deliberately
reviewed synthetic fixtures and curated milestone reports belong in Git.

## Fixed tiled-layout acceptance

`runM63TiledMatlabTests` requires native MATLAB and runs 28 reader/profile/
negative cases, including nine supported spacing/padding combinations and
three explicit zero-spacing rejections. It writes synthetic TeX/JSON evidence.
`runM63TiledWorkflowTests` additionally requires a real LuaLaTeX compiler and
tests single export, figure sets and repeated manifests (three cases).
Report a cross-runtime compiler bridge separately from native Windows TeX.

`runM63TiledIrTests` runs 15 handle-free schema/JSON/renderer/profile cases in
Octave or MATLAB. `runM63TiledTexTests` reruns those fixtures and compiles four
representative grids/profiles. Neither establishes native Octave tiledlayout
support. Inspect native-generated PDFs for cell/spans, labels, decorations,
85/170 mm profiles, simultaneous local/shared labels and tight spacing; compilation alone missed initial label
collisions. See [the contract](../docs/TILED_LAYOUTS.md).

## Security regression

`runS1SecurityTests` tests product collisions, overwrite/deletion preflight,
hostile stems, set traversal, compiler arguments and literal/markup boundaries
without requiring TeX. It runs 13 shared cases plus one Windows-specific name
case under MATLAB or five POSIX symlink cases under Octave. These are distinct
platform evidence, not skipped cases counted as passes. `runS1SecurityTexTests`
adds three real LuaLaTeX checks for spaces/dots/underscores, owned-asset overwrite
and disabled shell escape. Hosted jobs run both appropriate suites.

On Windows, `./test/runS1WindowsPathTests.ps1 -MatlabCommand matlab` adds three
native MATLAB checks for existing/dangling junction products and a deliberately
linked explicit parent directory. It creates isolated synthetic fixtures under
`.audit/`, removes only the created junctions, and preserves result evidence.

## Unsupported-content regression

`runM67UnsupportedTests` runs the native runtime matrix: 50 MATLAB cases and
52 Octave cases, with deterministic diagnostics, product sentinels, unchanged
source state and supported neighboring cases. `runM67UnsupportedTexTests`
requires a real compiler and exports nine fixtures covering hidden handles,
tagged text, legend reordering, reversed/custom colorbars, single-row hybrid,
explicit child-order 3-D, grouped bars and opaque/transparent overlays. Review source/compiled figures;
successful compilation alone cannot establish correct legend or color mapping.

M6.7 also updates an old M5.4 scatter3 rejection that became obsolete in M6.5
and makes older multi-object surface fixtures request child order explicitly.
New negative cases retain proof that unresolved depth sorting is rejected.
Bar IR tests cover optional resolved bounds and byte-identical JSON replay,
while absent fields preserve the established portable geometry.

## Determinism and performance

`runM68DeterminismTests` has eight stable checks for reference serialization,
precision boundaries, IR/JSON/TeX, planner/assets, PNG bytes, diagnostics and
native repeat reads. `runM68DeterminismWorkflowTests` has five real-compiler
checks over same-root/cross-root products, manifest order, source lifecycle and
failed/skipped manifests. MATLAB uses five figures including native tiled,
dual-Y and scatter3 scenes; Octave uses two supported common figures.
PDF bytes and runtime timings are deliberately excluded from byte comparisons.
Before/after large-data measurements are observations, never timing CI gates.
See [the determinism contract](../docs/DETERMINISM.md).

## Inherited legacy tests (separate exporter)

These exercise the separate `matlab2tikz(...)` exporter, not the modern public
API. The original MATLAB R2014a/R2014b and Octave 3.8 guidance describes upstream
history, not the current validated environment. Travis CI and personal Jenkins
instructions are historical; current automation is GitHub Actions.

The inherited entry point is `./runtests.sh octave-cli`. Alternatively, add
`test`, `src`, and `test/suites` to the runtime path and call `testHeadless`
or `testGraphical`. `makeLatexReport` creates a visual comparison report;
`makeTravisReport` is a retained historical formatter. Per-environment MD5
goldens detect byte changes, not scientific correctness.

`runM1ARegressionTests` and `runM1ATexCompileTests.ps1` cover legacy
compatibility and engine cases. `runM1B3DRegressionTests` checks camera behavior;
`runM1BGoldenReview.ps1` generates determinism/compile evidence but retains
`MANUAL_REVIEW_REQUIRED` until explicit semantic/visual approval. Never bulk
regenerate hashes to hide failures. Missing optional runtime dependencies are
classified with skip reasons; the harness does not install packages.

## Public API-freeze candidate

`runM70ApiContractTests` runs eight real compiler-backed contract cases in
MATLAB or Octave: result shapes/defaults, invalid options, safe collisions,
publication widths, rich-image planning, set inheritance/preflight and failed/
skipped manifests. Existing security/compiler suites cover the remaining
operational failures. See [API.md](../docs/API.md).

See the [test strategy](../docs/design/TEST_STRATEGY_2_0.md) and
[visual validation design](../docs/design/VISUAL_VALIDATION.md).
