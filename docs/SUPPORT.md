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
| **Supported** | 2-D line plots and multiline styling; markers; symmetric/asymmetric error bars; legends; linear/logarithmic and reversed axes; custom ticks; multiple/manual axes; axes-owned colorbars; deterministic IR migration/replay; publication profiles; explicit figure sets; scalar images/heatmaps with vector output; axes-owned free 2-D text; figure-owned arrows and double arrows. |
| **Supported with limitations** | Scatter with one constant style per series; grouped vertical bars with numeric categories and constant styles; traditional vertical `boxplot(...)` compounds in the documented narrow form; explicit hybrid image layers and opt-in deterministic `auto` planning; shared labels/title models where runtime ownership is recognized; Line3; orthographic Cartesian scalar surfaces and narrowly recognized Patch3 decoration. |
| **Experimental** | The pre-1.0 `m2t.export` and `m2t.exportSet` contracts; publication-profile tuning; FigureIR v2 and JSON/manifest schemas; internal `m2t2.*` interfaces. Tested experimental behavior is not a long-term compatibility promise. |
| **Unsupported** | Per-point/mapped/filled scatter semantics; `tiledlayout`/`nexttile`; `yyaxis`; polar plots; arbitrary annotations; stacked, horizontal, or categorical bar families; broad `boxchart` semantics; general patch compounds; general 3-D scenes; mesh, scatter3, and contour3; perspective, lighting, and material semantics; broad transparency; RGB/alpha and unsupported image mappings; general downsampling. |

## Important narrow boundaries

Scatter supports constant series-level marker, size, and color only. Image
support preserves scalar matrix data and explicit colormaps; hybrid output is a
deliberate backend choice, not a general raster fallback. Bar, boxplot, surface,
and Patch3 recognition is semantic and narrow: arbitrary compound graphics are
not accepted merely because they share a runtime object type.

Labels and titles represented as semantic axes properties are distinct from
free annotations. Free 2-D text is supported only in the documented axes-owned
data-coordinate form; arbitrary annotation shapes remain unsupported.

The inherited `matlab2tikz(...)` API has broader historical behavior. Its
presence does not expand the evidence-based m2tikz-next support claim.

## Diagnostics and future work

Unsupported objects, properties, or ownership relationships are expected to
fail explicitly with stable structured diagnostics. Silently dropping data or
decoration can create scientifically misleading output and is treated as a
product risk. Broader graphics coverage will be added through specific reader,
IR, renderer, and regression contracts rather than catch-all acceptance.

Pre-1.0 work includes selecting additional runtime validation targets and
stabilizing the public APIs. It does not imply that every unsupported MATLAB
graphics family is planned for the next release.
