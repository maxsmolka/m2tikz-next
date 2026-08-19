# M3.4 Explicit Hybrid Image Backend Report

## Executive Summary

M3.4 adds opt-in `ImageBackend='hybrid'` to `m2t.export` and `m2t.exportSet`.
Only normalized scalar ImageIR layers become deterministic lossless PNG assets;
PGFPlots axes, text, colorbars, legends, shared elements, and other series stay
vector. The default remains the byte-compatible M3.3 vector representation.

## Motivation

M3.3 established that pure matrix tables become expensive: its 250x250 fixture
was about 1.83 MB and required roughly 108 seconds to compile. M3.4 addresses
dense images explicitly, without screenshots, downsampling, hidden heuristics,
or legacy fallback.

## Public API

`m2t.export(...,'ImageBackend','vector')` selects the default M3.3 path;
`'hybrid'` selects PNG data layers. Unknown values return
`M2T:IMAGE_BACKEND_UNKNOWN`. No `auto`, `exportHybrid`, or raster-specific public
entry point exists.

## Hybrid Architecture

The runtime reader still creates handle-free FigureIR. Profile application is
unchanged. A renderer-owned plan contains backend, TeX, and normalized asset
payloads. The workflow validates output ownership, writes planned assets and
TeX, then calls the existing compiler. The compiler only resolves TeX inputs;
it does not inspect matrices or generate PNGs.

## Render Planning

Visible images are traversed in stable axes/series order. A hybrid plan assigns
`image-0001.png`, records dimensions and coordinate extents, derives RGB/alpha,
and provides relative paths to the TeX renderer. Vector plans contain no assets
and invoke the unchanged matrix renderer.

## Raster Format

PNG was selected because it is portable, lossless, LuaLaTeX-compatible, and
byte-deterministic with GNU Octave 11.3 `imwrite`. JPEG and BMP are not used.
No external ImageMagick dependency or graphics toolkit is involved.

## Scalar-to-Color Mapping

Vector and hybrid modes share one zero-based colormap-index function. For N rows
and CLim `[low,high]`, finite values use the clamped index
`floor((value-low)/(high-low)*N)`. Hybrid selects that exact normalized RGB row
and rounds channels to 8-bit values. Boundary and clamp behavior were validated
with `[0 1;2 3]`, CLim `[0 4]`, and four deliberately distinct colors.

## Resolution Model

One ImageIR cell becomes one PNG pixel. There is no resampling, averaging,
downsampling, display-DPI dependency, or lossy compression. Profile width does
not alter raster dimensions. Fully opaque PNGs omit alpha; NaN uses alpha zero.

## Coordinate Alignment

PGFPlots `addplot graphics` uses half-cell edges around the first and last
normalized centers. Pixel ordering incorporates coordinate monotonicity and
axes X/Y direction. The `[10 20 30]` by `[100 200]` test occupies exact extents
`[5,35]` by `[50,250]`. Hybrid currently rejects non-uniform centers because a
uniform raster cannot represent those widths without resampling.

## Colorbar Integration

ColorbarIR remains authoritative for axes association, CLim, colormap, ticks,
label, direction, orientation, and placement. The PNG supplies only the data
layer. Visual and compilation fixtures confirm the colorbar remains vector and
matches both backends.

## Asset Lifecycle

`field.tex` owns only `field-assets/`, with assets numbered deterministically.
Without overwrite, an existing managed directory is a structured collision.
With overwrite, the exact owned directory is removed and rebuilt, so stale
assets disappear without touching siblings. Analysis/planning failure writes no
assets. Compilation failures retain assets and logs for diagnosis.

## ExportResult Metadata

`result.render` additively exposes requested/effective image backend and absolute
asset paths. Existing result fields retain their meanings. Backend selection is
explicit, so requested and effective values are identical in M3.4.

## Figure Set / Manifest Integration

Set-level `ImageBackend` and lower-case per-entry `imageBackend` follow
`entry > set > export default`. `exportSet` still delegates every entry to
`m2t.export`. Manifest schema remains 1 because additive `imageBackend` and
relative `assets` fields preserve existing schema meaning and path portability.

## Determinism

Repeated identical render plans produced byte-identical TeX. Repeated exports
produced byte-identical PNG bytes. Names, ordering, paths, colormap quantization,
resolution, and lifecycle are deterministic; final asset names contain no UUID.

## Visual Validation

Nine vector/hybrid pairs were compiled and rasterized: base, custom colormap,
custom CLim, reverse Y, normal Y (`axis xy`), explicit extents, colorbar,
publication single-column, and publication double-column. Cairo rendering
confirmed matching orientation, cell edges, colors, limits, labels, geometry,
and colorbar. The vector text and axis elements remain sharp and independent of
the raster data layer. Fully opaque PNGs intentionally omit alpha for broad PDF
renderer compatibility; NaN transparency was tested separately.

## Numeric Raster Validation

A 2x2 matrix and four-color map assert exact PNG pixel RGB values, coordinate-
and-direction-aware row placement, opaque alpha omission, and zero alpha for the
known NaN pixel. `imread` confirms one-pixel-per-cell dimensions. Inf remains
explicitly unsupported before either backend renders.

## Performance

Windows GNU Octave 11.3 / TeX Live 2026 public-workflow measurements:

| Matrix | Backend | TeX | PNG | Total bytes | Render | LuaLaTeX | Total export |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 25x25 | vector | 17,171 | 0 | 17,171 | 0.084 s | 1.99 s | 2.12 s |
| 25x25 | hybrid | 1,022 | 246 | 1,268 | 0.158 s | 1.42 s | 1.64 s |
| 100x100 | vector | 263,636 | 0 | 263,636 | 1.03 s | 9.96 s | 11.01 s |
| 100x100 | hybrid | 1,027 | 861 | 1,888 | 0.013 s | 1.44 s | 1.47 s |
| 250x250 | vector | 1,722,125 | 0 | 1,722,125 | 6.72 s | 56.64 s | 63.38 s |
| 250x250 | hybrid | 1,027 | 2,201 | 3,228 | 0.019 s | 1.41 s | 1.44 s |
| 500x500 | hybrid | 1,027 | 4,638 | 5,665 | 0.050 s | 1.43 s | 1.50 s |

PNG size depends on data compressibility. The 250x250 hybrid result is over 500
times smaller and about 39 times faster to compile in this measurement. A
500x500 vector run was omitted as wasteful; hybrid remained practical.

## Tests

R1-R24 cover backend selection, vector compatibility, diagnostics, coordinates,
directions, CLim/colormap/NaN pixels, colorbar, profiles, mixed vector content,
multiple axes, set inheritance, manifest fields, TeX/PNG determinism, lifecycle,
paths with spaces, 250x250 compilation, and collisions. Static checks enforce
reader/profile/compiler separation and forbid screenshot APIs. A 50x50 custom-
colormap/colorbar/publication-profile hybrid smoke is wired into hosted CI.

## Cross-platform Results

Windows GNU Octave 11.3, `imwrite`, LuaLaTeX, and PGFPlots 1.18 validation is
green. The existing workflow pins GNU Octave 11.3.0 on hosted Linux/gnuplot and
now includes the M3.4 smoke. Hosted execution requires pushing the branch and is
therefore the remaining external evidence gate. MATLAB remains unvalidated.

## Hosted CI

The three existing jobs are retained. Repository policy adds the hybrid static
invariant. The TeX-preview scientific-workflow step adds only the compact M3.4
smoke; toolchain and dependency provisioning are unchanged.

## Backward Compatibility

Calls omitting ImageBackend still render vector images. Explicit vector output
is byte-identical to M3.3. Existing non-image TeX remains unchanged. ExportResult
and manifest additions are additive. The full M2-M3.3 regressions passed as the
final local gate.

## Limitations

Hybrid is limited to scalar scaled linear images with uniform centers. RGB,
meaningful source alpha, Inf, direct mapping, nonlinear color scale, and
non-uniform centers remain unsupported. PNG colors are 8-bit rendering artifacts
while exact scalar data remains in ImageIR. There is no automatic planner.

## Recommendation

1. Scalar heatmaps export explicitly with `ImageBackend='hybrid'`: yes.
2. The default remains M3.3 vector: yes.
3. Only the dense image layer is rasterized: yes.
4. Axes, text, colorbars, legends, and other series remain vector: yes.
5. Scalar-to-color semantics match the vector discrete rule: yes.
6. Matrix orientation and uniform coordinate extents are preserved: yes.
7. PNG output is byte-deterministic in the validated runtime: yes.
8. Asset names and lifecycle are deterministic: yes.
9. `Profile='publication'` works unchanged: yes.
10. `exportSet` supports set and entry selection: yes.
11. Manifest schema 1 remains compatible through additive fields: yes.
12. 250x250 hybrid materially outperforms vector: yes.
13. 500x500 hybrid is practical locally: yes.
14. The renderer remains handle-free: yes.
15. Windows is green; hosted Linux awaits the no-push external gate.
16. Full M2-M3.3 local regression is green; hosted Linux validation remains.
17. The evidence is sufficient for a later explicit automatic-planner design:
    yes, but no automatic policy belongs in M3.4.

CONDITIONAL GO FOR M3.5
