# Support status

m2tikz-next uses evidence-based capability claims. A supported figure should
export deterministically; content outside the documented boundary should
produce structured diagnostics rather than plausible but incomplete scientific
output.

## Validated environments

- GNU Octave 11.3 in hosted Linux CI and local validation;
- MATLAB R2026a Update 4 on Windows;
- TeX Live 2026, LuaLaTeX, and PGFPlots compatibility 1.18.x.

The MATLAB statement is exact: it does not imply validation of other releases
or platforms. See [MATLAB validation](MATLAB_VALIDATION_MATRIX.md) and
[MATLAB/Octave differences](MATLAB_OCTAVE_DIFFERENCES.md).

## Capability matrix

| Classification | Capability boundary |
| --- | --- |
| **Supported** | 2-D line plots and multiline styling; rich 2-D scatter with constant or per-point size, constant or per-point RGB, scalar mapped color, narrow edge/face modes, legends, and axes-owned colorbars; symmetric/asymmetric error bars; linear/logarithmic and reversed axes; custom ticks; multiple/manual axes; deterministic IR migration/replay; publication profiles; explicit figure sets; scalar images/heatmaps with vector output; axes-owned free 2-D text; figure-owned arrows and double arrows. |
| **Supported with limitations** | Grouped vertical bars with numeric categories and constant styles; traditional vertical `boxplot(...)` compounds in the documented narrow form; scalar and truecolor image layers with bounded constant/per-pixel alpha, explicit hybrid output, and deterministic `auto` planning; shared labels/title models where runtime ownership is recognized; Line3; orthographic Cartesian scalar surfaces and narrowly recognized Patch3 decoration. |
| **Experimental** | The pre-1.0 `m2t.export` and `m2t.exportSet` contracts; publication-profile tuning; FigureIR v2 and JSON/manifest schemas; internal `m2t2.*` interfaces. Tested experimental behavior is not a long-term compatibility promise. |
| **Unsupported** | Geographic/polar/categorical/table-backed scatter, scatter alpha, and non-evidence-backed edge/face modes; dynamic/nested/mixed/zero-spacing tiled layouts and outer-tile decorations; dual-axis variants outside the bounded contract below; polar plots; arbitrary annotations; stacked, horizontal, or categorical bar families; broad `boxchart` semantics; general patch compounds; general 3-D scenes; mesh/scatter3 outside the explicit scientific 3-D contract and contour3; perspective, lighting, and material semantics; broad transparency outside image-owned alpha; unsupported image mappings; general downsampling. |

Fixed MATLAB tiled layouts are supported with the explicit limits in
[TILED_LAYOUTS.md](TILED_LAYOUTS.md): whole-figure grids, explicit cells/spans,
shared labels, bounded spacing/padding, axes-owned decorations and profiles.
New evidence is MATLAB R2026a Update 5 on Windows; portable Octave layout IR
tests do not claim native Octave tiledlayout support. Linux compiler evidence
for this addition uses TeX Live 2025/Debian, separate from historical versions.

## Important narrow boundaries

Rich native MATLAB scatter3 and constant-color transparent-face wire meshes
are supported with limitations in [SCIENTIFIC_3D.md](SCIENTIFIC_3D.md).
New scenes distinguish single-object depth sorting from source-explicit
child-order combinations; manual camera/complex occlusion is not approximated.
Native Update 5 evidence does not imply native Octave 3-D parity.

Native MATLAB `yyaxis` line/scatter combinations are supported with limitations
in [DUAL_Y_AXES.md](DUAL_Y_AXES.md): explicit side ownership, independent limits,
scales/ticks/labels/colors, shared numeric X, linked legends, colorbars, tiled
layouts and 85/170 mm profiles. Native Update 5 evidence is separate from
portable Octave IR/compiler tests; native Octave yyaxis parity is not claimed.

Scatter preserves source `SizeData` area through the deterministic conversion
`PGFPlots radius = sqrt(SizeData) / 2 pt`; constant and per-point areas are
supported. Active `flat` edge/face roles may use constant RGB, N-by-3 point RGB,
or N scalar values. Scalar values remain point metadata and use the axes CLim,
colormap, and ColorbarIR; explicit RGB never receives invented CLim semantics.
Opaque `none`, `flat`, and constant-RGB edge/face roles are supported where the
normalized marker has a faithful PGFPlots representation. Per-point sizes use
order-preserving PGFPlots plot segments (after explicit 3-D depth ordering when
requested by the scene); many unique sizes therefore grow
TeX command count rather than being silently quantized. Image
support preserves scalar matrix data, truecolor channels, image-owned alpha,
and explicit colormaps; hybrid output is a deliberate image-layer choice, not a
general raster fallback. Bar, boxplot, surface,
and Patch3 recognition is semantic and narrow: arbitrary compound graphics are
not accepted merely because they share a runtime object type.

Labels and titles represented as semantic axes properties are distinct from
free annotations. Free 2-D text is supported only in the documented axes-owned
data-coordinate form; arbitrary annotation shapes remain unsupported.

The inherited `matlab2tikz(...)` API has broader historical behavior. Its
presence does not expand the evidence-based m2tikz-next support claim.

## Diagnostics and future work

Large-data handling retains all supported samples/cells and uses no automatic
reduction. This is distinct from finite TeX numeric precision and image-owned
8-bit PNG encoding. See [LARGE_DATA.md](LARGE_DATA.md) for measured scale,
explicit representation choices, compiler resource limits and the deferred
reduction-API decision. Timing measurements are not CI thresholds.

Unsupported objects, properties, or ownership relationships are expected to
fail explicitly with stable structured diagnostics. Silently dropping data or
decoration can create scientifically misleading output and is treated as a
product risk. Broader graphics coverage will be added through specific reader,
IR, renderer, and regression contracts rather than catch-all acceptance.

Pre-1.0 work includes selecting additional runtime validation targets and
stabilizing the public APIs. It does not imply that every unsupported MATLAB
graphics family is planned for the next release.
