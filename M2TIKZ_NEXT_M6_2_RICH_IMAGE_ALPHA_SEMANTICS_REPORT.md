# M6.2 Rich Image & Alpha Semantics Report

## Executive Summary

M6.2 adds explicit truecolor and image-owned alpha semantics to the existing
scalar-image architecture. Rich modes use the image-only hybrid backend; axes,
text, overlays, annotations, and colorbars remain vector. No data is resized,
downsampled, flattened to grayscale, or silently made opaque.

## Scope

The supported slice is rectangular 2-D scalar or RGB image data with finite
monotonic placement, normal/reversed axes direction, and bounded alpha.

## Baseline

Branch `m6.2/rich-image-alpha-semantics` started clean at `5a982d2`, the M6.1
merge on `public/main`. Pre-change Public Preview passed. The established 178
portable tests plus 29 M6.1 tests passed before product changes.

## Previous Image Contract

The previous contract supported nonempty scalar matrices, scaled axes color
mapping, opaque alpha, vector tables, explicit hybrid PNG, and threshold-based
auto selection. RGB, meaningful alpha, and direct mapping were rejected.

## Supported Rich Image Slice

Scalar scaled/direct data, double/single/uint8/uint16 truecolor RGB, opaque or
constant/per-pixel alpha, placement, direction, hybrid assets, deterministic
planning, profiles, colorbars for scalar data, and mixed figure sets are covered.

## Explicit Non-Goals

Texture mapping, warped/nonrectangular geometry, volumetric stacks, mapped
alpha, RGB NaN, general transforms, 3-D textured surfaces, UI images, callbacks,
whole-figure screenshots, and automatic downsampling remain unsupported.

## Runtime Evidence

The reader inspects CData, mappings, alpha, coordinates, visibility, and parent
axes capabilities. It contains no OS, toolkit, or runtime-version branch.

## Image IR

FigureIR v2 receives additive `colorMode`, `directIndexBase`, `alphaMode`, and
`alphaData` fields. CData meaning is explicit, handles are absent, and old v2
documents receive scalar/opaque defaults.

## Scalar Semantics

Scalar values remain numeric data. Scaled values preserve CLim/colormap; direct
values preserve integer indices and the source class index base. Scalar NaN is
an explicit missing transparent cell and Inf is rejected.

## RGB Semantics

M-by-N-by-3 double/single values in `[0,1]` and uint8/uint16 values normalized
by their class maxima are supported. RGB has mapping `none`, no CLim meaning,
and no synthetic colorbar.

## Alpha Semantics

Unmapped scalar or M-by-N alpha is supported for double/single `[0,1]`, uint8,
and uint16. It is normalized without clamping. Alpha is encoded unpremultiplied
to 8-bit PNG; invalid shape, range, class, finiteness, or mapping fails.

## Color Mapping

Scaled scalar mapping retains axes limits and colormap bins. Direct scalar
mapping carries a zero/one index base and clamps only at the available colormap
boundary. RGB is independent of axes color mapping.

## Colorbar Integration

Scalar images retain ColorbarIR. RGB does not activate point-meta/colormap TeX
and never creates a colorbar. Mixed scalar/RGB axes retain only genuine scalar
color ownership.

## Coordinate / Orientation Semantics

Existing pixel-center expansion, half-cell hybrid extents, monotonic ascending
or descending coordinates, and XDir/YDir orientation rules are unchanged.

## Reader Changes

`readImage` now normalizes bounded RGB, alpha, and direct scalar indices and
raises E047-E052/E054 for malformed or unsupported source semantics.

## Renderer Changes

The vector renderer accepts only opaque scalar images. Hybrid planning converts
normalized scalar or RGB data and image alpha into exact-size RGBA layers.

## Hybrid Backend

RGB and nonopaque alpha require hybrid output. Only the image layer is raster;
all scientific axes and supported overlays remain vector.

## Vector Backend

Opaque scalar scaled/direct images remain valid. Forced vector for RGB or
nonopaque alpha fails as E053 rather than changing backend silently.

## Auto Planner

The isolated planner retains `default-v1` and its 4096-cell threshold. Semantic
requirements precede size selection and are deterministic.

## Planner Reason Codes

`truecolor_requires_hybrid` and `alpha_requires_hybrid` are stable additive
reasons. Existing reasons remain unchanged.

## PNG Determinism

Repeated normalized input produced identical RGBA arrays and byte-identical PNG
files with the same encoder after time-metadata removal. Cross-encoder byte
identity is not claimed; pixel/channel semantics are deterministic.

## Diagnostics

E047-E054 distinguish malformed CData, dimensionality, RGB, alpha data/mapping,
color mapping, forced-vector rich images, and coordinates.

## Synthetic Fixtures

Twenty positive focused cases cover scalar/RGB/alpha classes and modes, direct
mapping, planner reasons, hybrid pixels, NaN, replay, lifecycle, placement,
mixed color ownership, and a 512-by-512 case.

## Negative Controls

Six controls cover alpha shape/range/mapping, RGB NaN, invalid IR dimensions,
and nonuniform hybrid coordinates. Forced vector is also asserted precisely.

## JSON Replay

Rich RGB plus per-pixel alpha replays and validates exactly. Old FigureIR v2
image documents receive compatible defaults without a schema bump.

## Determinism

Repeated IR, planner result, TeX, asset metadata, pixel order, alpha order, and
same-encoder PNG bytes match.

## Lifecycle

Reader/export checks preserve CData, AlphaData, mappings, X/Y placement, axes
state, color mapping, direction, visibility, and colorbar ownership.

## MATLAB Validation

MATLAB R2026a Update 4 on Windows launched successfully and passed the focused
M6.2 suite 26/26. This does not generalize to other MATLAB versions.

## Octave Validation

Local GNU Octave 11.3 passed 26/26. The exact hosted-CI GNU Octave 11.3.0
Linux/gnuplot image also passed 26/26.

## TeX/PDF Validation

Eleven focused exports compiled: scalar vector/hybrid, RGB, RGB+alpha,
scalar+alpha, colorbar, line/scatter overlays, 85/170 mm profiles, and figure set.
Public Preview also compiled examples 01-05, 11, 12, and legacy smoke.

## Visual Validation

Rendered pages were reviewed for RGB channel order, constant/per-pixel alpha,
scalar gradient/colorbar, scatter overlay, orientation, placement, and profile
widths. No clipping, background rectangle, channel swap, or orientation defect
was observed.

## Publication Profile

85 mm and 170 mm rich-image outputs compile. Pixel aspect, alpha, and exact
asset scaling remain intact; no profile calibration changed.

## Figure Sets

A rich-image, line, and grouped-bar set compiles with relative assets, inherited
profile/backend settings, semantic planner metadata, and no cross-entry state.

## Performance

A 512-by-512 RGB image with per-pixel alpha retained all 262,144 pixels. Local
Octave measured about 0.10 s analysis, 0.29 s export/PNG, 1.55 s LuaLaTeX, and
1.95 s total. TeX was 796 bytes, PNG 62,881 bytes, and PDF 279,553 bytes.

## Documentation

README, support, image plots/backends, planner, diagnostics, runtime differences,
examples, and ADR-0021 describe the new boundary.

## Confidentiality

All fixtures are analytic and synthetic. The confidentiality gate and a strict
restricted-term scan pass with zero matches.

## Regression

Public Preview passes with 140 core cases. The extended portable set passes
233/233: the established 178, M6.1 29, and M6.2 26. M3.3 18/18, M3.4 24/24,
M3.5 24/24, focused TeX 11/11, architecture, documentation, citation,
confidentiality, actionlint, and whitespace checks pass.

## Product Source Impact

Product source changed: yes. Image reader/IR/renderer, hybrid asset construction,
axes color activation, planner classification, and diagnostics changed additively.

## Public API Impact

No new public option was introduced. Existing `ImageBackend` values remain the
complete control surface.

## Remaining Image Limitations

The explicit non-goals remain, along with 8-bit PNG quantization, same-encoder
byte-determinism scope, uniform hybrid cell spacing, and figure-level backend
selection when several images share one export.

## Recommendation

The evidence supports review as an additive, bounded scientific image feature.

## Completion Questions

1. Before M6.2: opaque scaled scalar images with vector/hybrid/auto output.
2. Scalar images unchanged: yes.
3. Truecolor RGB: yes.
4. RGB: M-by-N-by-3 double/single `[0,1]`, uint8, and uint16.
5. RGB avoids invented CLim: yes.
6. Constant alpha: yes.
7. Per-pixel alpha: yes.
8. Alpha shapes: scalar or exactly M-by-N.
9. Alpha classes/ranges: double/single `[0,1]`, uint8, uint16.
10. AlphaDataMapping: `none` only.
11. Alpha is ImageIR-owned: yes.
12. Scalar CLim preserved: yes.
13. Scalar colormap preserved: yes.
14. Scalar ColorbarIR integration: yes.
15. RGB avoids fake colorbar: yes.
16. Direct CDataMapping: yes, for finite integer scalar indices.
17. Representation: mapping plus explicit zero/one `directIndexBase`.
18. Unsupported mapping diagnostic: E052.
19. NaN semantics explicit: scalar missing/transparent; RGB NaN unsupported.
20. XData/YData placement preserved: yes.
21. YDir preserved: yes.
22. RGB+alpha through hybrid: yes.
23. Scalar+alpha: yes, through hybrid.
24. Forced vector: opaque scalar scaled/direct only.
25. Hybrid required: RGB or nonopaque alpha.
26. Auto deterministic: yes.
27. New reasons: `truecolor_requires_hybrid`, `alpha_requires_hybrid`.
28. PNG deterministic within documented boundary: yes.
29. Alpha preserved: yes.
30. Orientation correct: yes.
31. Channel ordering correct: yes.
32. Reader capability-based: yes.
33. IR handle-free: yes.
34. Renderer runtime-neutral: yes.
35. Old FigureIR readable: yes.
36. JSON covers supported rich modes: yes.
37. Repeated outputs deterministic: yes.
38. Caller figure state preserved: yes.
39. Supported cases compile: yes, 11/11 focused.
40. RGB visual review: pass.
41. Alpha visual review: pass.
42. Scalar colorbar correct: yes.
43. 85/170 mm profiles: pass.
44. Mixed exportSet: pass.
45. Public example: yes, example 12.
46. 512-by-512 tested: yes.
47. Scale result: 62,881-byte PNG, 796-byte TeX, about 1.95 s total.
48. Pixel data dropped: no.
49. Alpha removed: no.
50. Resized/downsampled: no.
51. Scalar-image regression: no.
52. M3.3: 18/18 pass.
53. M3.4: 24/24 pass.
54. M3.5: 24/24 pass.
55. M6.1: 29/29 pass.
56. Public Preview: pass.
57. Portable regressions: 233/233 pass.
58. Architecture validation: pass.
59. Documentation validation: pass.
60. Citation validation: pass.
61. Confidentiality validation: pass.
62. YAML/actionlint: pass.
63. `git diff --check`: pass.
64. New public API option: no.
65. Limitations: the explicit non-goals and remaining limitations above.
66. Ready for PR: yes, subject to normal review and hosted CI confirmation.

## Completion Decision

READY FOR M6.2 RICH IMAGE & ALPHA SEMANTICS PR
