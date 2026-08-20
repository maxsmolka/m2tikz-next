# M6.1 Rich Scatter Semantics Report

## Executive Summary

M6.1 extends the narrow constant-style scatter path into an explicit rich 2-D
scatter contract. Constant and per-point marker areas, constant and per-point
RGB, scalar mapped color, opaque edge/face roles, legends, visibility, and
axes-owned colorbars are normalized without handles and rendered without
runtime access. Unsupported states fail with dedicated diagnostics. No public
API option, schema-version bump, fallback, rasterization, or downsampling was
introduced.

## Scope

The implemented scope is finite 2-D Cartesian scatter discovered from the
figure. All fixtures are deterministic, analytic, synthetic, and redistributable.
Scatter3, geographic/polar/categorical/table-backed semantics, nonopaque alpha,
callbacks, hidden runtime children, and broad marker-object behavior remain out
of scope.

## Baseline

The branch began clean at `bdfe457` (`v0.5.0`, `public/main`) on
`m6.1/rich-scatter-semantics`. The pre-change Public Preview passed all 88 core
reader/renderer cases, the five curated examples, legacy smoke, six LuaLaTeX
compilations, architecture invariants, documentation links, and citation
validation. The released base and final tree were also exercised through the
same 178-case extended portable milestone set.

## Previous Scatter Contract

Before M6.1, the reader accepted finite 2-D X/Y only when `SizeData` was one
constant finite nonnegative value, CData resolved to one RGB triplet, the marker
face was `none`, and the edge resolved to one color. It stored one color, marker,
and diameter-like marker size. Per-point size/color, scalar mapping, filled
markers, and scatter3 raised the generic E007 unsupported-property diagnostic.

## Supported Rich Scatter Slice

The supported slice includes constant or per-point marker area; constant RGB,
N-by-3 point RGB, or N scalar color values; source-order-preserving points;
supported marker symbols; opaque `none`, `flat`, and constant-RGB edge/face
roles; DisplayName, visibility, legend ownership; axes CLim and colormap; and
ColorbarIR integration. Multiple scatter series and mixtures with lines or
scalar images are supported.

## Explicit Non-Goals

M6.1 does not support scatter3, geographic or polar scatter, categorical or
table-backed coordinates, arbitrary alpha, texture markers, datatips, brushing,
callbacks, arbitrary runtime children, or general large-data reduction.

## Runtime Evidence

GNU Octave 11.3 on Windows exposes a native `scatter` object. The exact hosted
CI image, GNU Octave 11.3.0 on Linux with gnuplot, exposes a capability-proven
scatter `hggroup`. Both expose the required X/Y, SizeData, CData, marker,
edge/face, DisplayName, and visibility semantics and pass the 29-case focused
suite. The reader contains no OS, toolkit, or version branch.

MATLAB R2026a Update 4 was present but failed before product startup with the
previously observed environment error, `System Error: File system inconsistency`.
No product workaround was added. The recorded MATLAB baseline remains exact,
but focused M6.1 native-reader execution could not be renewed in that broken
local environment.

## Scatter IR

FigureIR remains version 2. ScatterIR additively gains `sizeMode`, `colorMode`,
`colorData`, `edgeMode`, `edgeColor`, `faceMode`, and `faceColor`. `markerSize`
is scalar for `constant` and one value per point for `per_point`. Color data is
empty for `constant_rgb`, N-by-3 for `per_point_rgb`, and an N-vector for
`scalar_mapped`. Modes remove array ambiguity. The IR remains handle-free,
runtime-neutral, deterministic, JSON-serializable, and schema-validated.

## Size Semantics

Source Scatter `SizeData` is marker area in points squared. The reader stores a
normalized marker diameter `sqrt(SizeData)`. The renderer emits PGFPlots radius
`sqrt(SizeData) / 2 pt`. This preserves area and relative-size meaning without
an arbitrary scale factor. Per-point sizes are emitted in source order as
consecutive explicit plot segments. Many unique sizes increase TeX command
count; values are never quantized or collapsed.

## Color Semantics

Constant RGB remains a single series color. N-by-3 RGB is retained exactly and
rendered through deterministic symbolic scatter classes. N scalar values remain
numeric point metadata. Explicit RGB does not acquire invented CLim semantics,
and scalar metadata is not pre-converted to RGB.

## Colorbar Integration

Scalar scatter uses the existing axes ColorMappingIR. Axes CLim, linear color
scale, colormap stops, point metadata, and ColorbarIR label, limits, ticks, and
orientation remain axes/figure-level semantics. A scalar image and scalar
scatter on the same axes share one mapping. Unsupported nonlinear scatter color
mapping raises E046.

## Edge / Face Semantics

Edge and face roles are independently normalized as `none`, `constant`, or
`data`. Constant edge plus data-driven face, data-driven edge plus no face, and
other faithful opaque combinations are preserved. Nonopaque alpha, `auto` and
other unproven roles, filled open-only marks, and distinct unsupported
per-point edge/face behavior fail explicitly.

## Marker Mapping

The established marker normalization remains authoritative. Filled variants are
selected only through the normalized marker name; M6.1 does not create a broad
marker subsystem. Open-only plus, asterisk, point, and x markers cannot claim a
filled face.

## Reader Changes

The reader validates finite coordinate cardinality, 2-D dimensionality, source
marker areas, active CData shape and range, opacity, and edge/face ownership.
Native scatter and capability-proven hggroup representations enter the same
normalizer. Figure and axes state is only read.

## Renderer Changes

The renderer consumes ScatterIR only. Constant simple scatter retains its
compact coordinate representation. Explicit RGB uses stable symbolic classes;
scalar values use native point meta and the axes colormap. Per-point sizes use
source-order-preserving constant-radius segments because the tested LuaLaTeX
PGFPlots marker-size hook compiled but did not apply different radii. The chosen
representation is explicit and visually verified.

## Diagnostics

The new noncolliding diagnostics are E040 MalformedScatterData, E041
UnsupportedScatterSize, E042 UnsupportedScatterColor, E043
UnsupportedScatterTransparency, E044 UnsupportedScatterMarkerStyle, E045
UnsupportedScatterDimensionality, and E046 UnsupportedScatterColorMapping.
E039 remains reserved by the prior 3-D diagnostic contract. Public workflow
classification recognizes every new code.

## Synthetic Fixtures

S01-S14 cover constant and varying sizes, constant and point RGB, scalar
mapping, colorbar, combined size/color, legend, transformed axes, multiple
series, scatter plus line, scatter plus scalar image, edge/face roles, and
visibility. Example 11 uses an analytic damped sinusoid with varying marker area
and scalar color.

## Negative Controls

N01-N08 cover scatter3, nonfinite coordinates, alpha where the runtime exposes
that capability, unsupported face mode, malformed SizeData, malformed active
CData, invalid normalized coordinates, and incompatible axes color scale. A
gnuplot hggroup that cannot construct a marker-alpha property records that
capability boundary instead of pretending native parity.

## JSON Replay

Replay passes for constant size/constant RGB, varying size/constant RGB,
constant size/point RGB, varying size/point RGB, scalar mapped color, and scalar
mapped color with the shared mapping contract. Pre-M6.1 v2 scatter documents
normalize to their old constant-size, constant-edge, unfilled defaults and
remain readable. No schema bump was required.

## Determinism

Repeated IR JSON and TeX are byte-identical. Point, size, metadata, symbolic
color-class, series, and plot-segment order follow normalized source order.

## Lifecycle

Focused before/after checks cover XData, YData, SizeData, CData, marker,
edge/face settings, axes CLim, colormap, colorbar visibility, series visibility,
axes limits, and figure visibility. Reader execution leaves all values unchanged.

## MATLAB Validation

Focused MATLAB execution is environment-blocked before product startup. The
failure is not a reader or renderer result, and no compatibility claim beyond
the recorded `Validated with MATLAB R2026a Update 4 on Windows` baseline is made.

## Octave Validation

The focused suite passes 29/29 both in local GNU Octave 11.3 and in the pinned
Hosted-CI GNU Octave 11.3.0 Linux/gnuplot image. The latter directly validates
the scatter hggroup path rather than substituting a native-object fixture.

## TeX/PDF Validation

Nine focused standalone documents compile with LuaLaTeX: all six size/color
mode combinations plus multiple scatter, scatter plus line, and scatter plus
scalar image. Public example 11 and the mixed figure set also compile. No fatal
TeX error, missing point table, malformed metadata, or clipping was observed.

## Visual Validation

Rendered PDFs were reviewed for varying size, point RGB, scalar gradient,
scalar gradient plus colorbar, combined size/RGB, multiple series, scatter plus
line, and scatter plus image. Marker diameters visibly follow 4/6/8/10 pt,
explicit RGB points remain distinct, scalar values follow the shared gradient,
and the colorbar range matches CLim. The example remains unclipped.

## Publication Profile

Rich scatter compiles at single-column 85 mm and double-column 170 mm. The
publication transform preserves the complete marker-size vector and therefore
does not destroy relative point-size meaning. No global profile recalibration
was made.

## Figure Sets

A mixed rich-scatter/line `m2t.exportSet` case compiles, repeats with a
byte-identical manifest, uses relative manifest paths, inherits the publication
profile, and keeps colormap state out of the line artifact. The rich scatter is
also compiled at 170 mm.

## Performance

The 10,000-point synthetic case uses constant size with scalar mapped color and
no downsampling. Windows Octave measured about 0.015 s for IR validation, 3.65 s
for TeX rendering, and 538,638 bytes of TeX; the pinned Linux image measured
about 0.026 s, 2.23 s, and 538,633 bytes. Local LuaLaTeX compilation took about
11.1 s and produced a 44,038-byte PDF. These are evidence points, not a general
large-data performance guarantee.

## Documentation

README, support status, diagnostics, MATLAB/Octave differences, example index,
and ADR-0020 document the explicit modes, size conversion, color ownership,
colorbar behavior, limitations, and runtime boundary.

## Confidentiality

All additions are synthetic and public-safe. The repository confidentiality
check passes; no restricted validation source, identifier, or nonpublic path is
referenced.

## Regression

Public Preview passes with 114 core cases (the prior 88 minus three obsolete
negative assertions plus 29 focused cases), examples 01-05 and 11, legacy smoke,
and seven curated LuaLaTeX compilations. The extended portable milestone set
passes 178/178. The nine focused TeX documents, mixed figure set, architecture
invariants, documentation links, citation validation, confidentiality check,
YAML/actionlint, and whitespace check pass. No existing supported simple scatter
behavior regressed.

## Product Source Impact

Product source changed: yes. The reader, additive ScatterIR defaults/migration
and validation, renderer, axes color-map activation, and unsupported diagnostic
classification changed. No legacy matlab2tikz reader/renderer behavior changed.

## Public API Impact

No new public option was introduced. Existing `m2t.export` and `m2t.exportSet`
discover rich scatter automatically. Internal FigureIR v2 received additive
fields under its existing compatibility policy.

## Remaining Scatter Limitations

Remaining limitations include scatter3; geographic, polar, categorical, and
table-backed scatter; alpha below one and alpha arrays; non-evidence-backed
edge/face modes; filled open-only markers; arbitrary marker objects; and command
growth for many unique marker sizes. There is no automatic downsampling.

## Recommendation

The evidence supports review as an additive pre-1.0 feature. Hosted CI retains
the three existing job names and now exercises focused rich ScatterIR/renderer,
example, TeX, and mixed-set behavior without requiring licensed MATLAB.

## Completion Questions

1. Before M6.1: constant finite size, one RGB color, unfilled 2-D scatter only.
2. Constant SizeData: yes.
3. Per-point SizeData: yes.
4. Conversion: PGFPlots radius is `sqrt(SizeData) / 2 pt`.
5. Constant RGB: yes.
6. Per-point RGB: yes, retained as N-by-3 data.
7. Scalar per-point CData: yes, retained as point metadata.
8. Scalar CData preserves axes CLim: yes.
9. Scalar CData preserves axes colormap: yes.
10. Scalar scatter integrates with ColorbarIR: yes.
11. Filled/unfilled state is preserved: yes, for faithful marker/role combinations.
12. Constant marker edge color is preserved: yes.
13. Constant marker face color is preserved: yes.
14. Unsupported edge/face combinations: unproven automatic modes, nonopaque
    roles, filled open-only markers, and unsupported distinct per-point roles.
15. Per-point alpha arrays are unsupported: yes.
16. Scatter3 is unsupported: yes, E045.
17. Malformed SizeData is diagnosed precisely: yes, E041.
18. Malformed CData is diagnosed precisely: yes, E042.
19. The reader remains capability-based: yes.
20. The IR is handle-free: yes.
21. The renderer is runtime-neutral: yes.
22. JSON replay covers all new modes: yes.
23. Old FigureIR documents remain readable: yes.
24. Repeated IR/TeX is deterministic: yes.
25. Point ordering is deterministic: yes, source order is retained.
26. Caller figure state is preserved: yes.
27. Supported cases compile with LuaLaTeX: yes.
28. Varying marker size is scientifically correct: yes, visually and numerically.
29. Per-point RGB renders correctly: yes.
30. Scalar color mapping renders correctly: yes.
31. Colorbar integration renders correctly: yes.
32. 85 mm and 170 mm publication profiles pass: yes.
33. Mixed `m2t.exportSet` passes: yes.
34. A public example was added: yes, example 11.
35. A 10k-point scale case was tested: yes.
36. Approximate size/time: 539 kB TeX, 2-4 s rendering, 11.1 s compilation.
37. Data silently dropped or simplified: no.
38. Existing scatter behavior regressed: no.
39. Public Preview passed: yes.
40. Existing portable regressions passed: yes, 178/178.
41. Architecture validation passed: yes.
42. Documentation validation passed: yes.
43. Citation validation passed: yes.
44. Confidentiality validation passed: yes.
45. YAML/actionlint passed: yes.
46. `git diff --check` passed: yes.
47. New public API option introduced: no.
48. Remaining limitations: the explicit non-goals and unique-size command growth
    listed above.
49. M6.1 ready for PR: yes, subject to normal review and hosted CI confirmation.

## Completion Decision

READY FOR
