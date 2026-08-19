# M3.3 Image / Heatmap Support Report

## Executive Summary

M3.3 adds first-class scalar 2-D `imagesc` support to `m2t.export` and
`m2t.exportSet`. The implementation is additive: a dedicated ImageIR crosses
the existing reader/IR/renderer boundary, uses PGFPlots `matrix plot*`, reuses
axes ColorMappingIR and ColorbarIR, and adds no screenshot or legacy fallback.

## Runtime Representation Audit

GNU Octave 11.3 was inspected directly on Windows. `imagesc([1 2 3;4 5 6])`
creates an axes-owned `image` with exact double 2x3 CData, `XData=[1 3]`,
`YData=[1 2]`, scaled CData mapping, and scalar AlphaData 1. Explicit uniformly
spaced vectors are exposed as endpoint pairs (`[-2 2]`, `[-1 1]`). Default
image axes use `YDir=reverse`; `axis xy` produces `YDir=normal`. Changed CLim
and custom colormap rows are available on the axes. Colorbar semantics remain a
separate axes-owned runtime object. RGB input has MxNx3 CData and direct mapping.

## ImageIR

`m2t2.image` contains `id`, `kind`, `displayName`, `visible`, expanded cell-center
`x` and `y`, exact `cdata`, `mapping=scaled`, and `interpolation=nearest`. It
contains no handles. FigureIR remains schema version 2, and JSON normalization
recognizes the additive series kind.

## Coordinate Normalization

One coordinate per row/column is retained. A two-value endpoint pair is expanded
with `linspace` to the matrix dimension. Coordinates must be finite and strictly
monotonic. This interpretation is confined to the reader; renderer code is
runtime-, toolkit-, OS-, and Octave-version-unaware.

## Matrix Orientation

CData is stored and emitted as rows(y)-by-columns(x), row 1 followed by row 2,
without transpose or reversal. Axes `x dir` and `y dir` preserve orientation.
The unique matrix `[1 2 3;4 5 6]` is asserted in IR and emitted-table order, and
both normal and reversed Y fixtures compile.

## PGFPlots Representation

The renderer uses `matrix plot*`, explicit X/Y table coordinates, and one row
per cell. It includes both the original scalar value and a direct colormap index.
This representation compiled with LuaLaTeX and PGFPlots compatibility 1.18 for
all supported fixtures. It is deterministic and honest about linear output-size
growth.

## Color Mapping

Axes ColorMappingIR remains authoritative for CLim and colormap. For N colormap
rows, linear scaled CData is converted to the clamped zero-based index
`floor((value-low)/(high-low)*N)`. The exact original scalar is retained beside
that index. Colorbar limits, ticks, labels, orientation, direction, placement,
and ownership continue through ColorbarIR without duplication.

## Colormap Serialization

Every axes containing an image receives an explicitly named PGFPlots colormap.
RGB components use the existing locale-independent 15-significant-digit numeric
formatter. Repeated rendering is byte-identical. Direct indexing avoids TeX-side
linear interpolation between MATLAB/Octave image color bins.

## Non-finite Values

NaN is preserved in ImageIR and emitted as a missing matrix cell. Positive and
negative infinity produce `M2T2:E_IMAGE_NONFINITE_UNSUPPORTED`; neither is
silently clamped.

## RGB / Alpha Decision

True-color MxNx3 data is not added in M3.3 and returns
`M2T2:E_IMAGE_RGB_UNSUPPORTED`. Non-default alpha returns
`M2T2:E_IMAGE_ALPHA_UNSUPPORTED`. This keeps scalar axes-owned mapping precise
and avoids silently discarding image transparency.

## Profile Integration

`Profile='publication'` works unchanged. It adjusts physical FigureIR size and
TeX typography only; matrix, centers, CLim, colormap, directions, and colorbar
semantics remain unchanged.

## Figure Set Integration

An image is an ordinary `m2t.exportSet` entry. The existing single-export
delegation, result aggregation, overwrite behavior, and manifest schema are
unchanged. H10 compiles an image entry and validates its manifest.

## Performance

Windows Octave 11.3 / TeX Live 2026 measurements:

| Matrix | TeX bytes | Reader | Renderer | LuaLaTeX |
| --- | ---: | ---: | ---: | ---: |
| 25x25 | 29,536 | 0.033 s | 0.346 s | 2.32 s |
| 100x100 | 290,000 | 0.017 s | 14.08 s | 20.00 s |
| 250x250 | 1,827,501 | 0.018 s | 84.53 s | 108.26 s |

The practical pure-PGFPlots cost becomes noticeable around 100x100 and is
unreasonable for routine rebuilds at 250x250. No automatic downsampling or
raster substitution was introduced.

## Visual Validation

Generated PDFs were rasterized and inspected for the base unique matrix,
explicit extents, custom CLim, custom three-row colormap, both Y directions,
and a labeled vertical colorbar. Cell layout, orientation, relative color bins,
axis limits, colorbar range, label, and geometry were correct. Direct colormap
indexing fixed the initially observed TeX interpolation of discrete source bins.
Source-window raster export was not reliable in the local headless FLTK session;
the comparison therefore combined runtime property evidence, exact numeric table
assertions, compiled PDF inspection, and the normal/reverse visual pair.

## Tests

H1-H16 plus Inf and JSON-replay regressions cover matrix values, coordinates, orientation,
CLim, colormap, colorbar, profile, multiple axes, exportSet, NaN, determinism,
25x25/100x100 fixtures, and RGB/alpha/Inf diagnostics. A compact 20x20 custom-
colormap, colorbar, publication-profile smoke test is wired into hosted CI.
Static renderer checks now also forbid profile, exportSet, or compiler coupling
in the image renderer. Unsupported image diagnostics are asserted through both
`m2t.export` and `m2t.exportSet`.

## Cross-platform Results

Windows GNU Octave 11.3 and LuaLaTeX validation is green. M2-M3.3 regression,
public-preview, examples, metadata, static-invariant, and workflow checks pass
locally. The existing hosted
workflow provisions pinned GNU Octave 11.3.0 on Linux/gnuplot; the new smoke is
configured there, but hosted execution requires the branch to be pushed and is
therefore an external evidence gate for this uncommitted local milestone.
MATLAB support remains unvalidated.

## Hosted CI

The three-job workflow is retained. Only the TeX-preview scientific-workflow
step gains `runM33ImageSmokeTest`; package provisioning and runtime pins are
unchanged. The smoke verifies success and PDF existence for a 20x20 heatmap.

## Backward Compatibility

The public call syntax, FigureIR version, profile API, figure-set API, compiler,
and backend are unchanged. Existing image-bearing colorbar workflows now render
their matrix instead of the intentional pre-M3.3 placeholder omission. All
other supported series continue through their existing renderers.

## Limitations

RGB, non-default alpha, Inf, direct-indexed CData, nonlinear image color scale,
and invalid/non-monotonic coordinates remain explicit unsupported cases. No
non-uniform full-vector runtime evidence is available from Octave because common
`imagesc` calls expose only endpoints. Large matrices produce large, slow TeX.

## Recommendation

1. Common scalar `imagesc` figures export through `m2t.export`: yes.
2. Matrix values are preserved exactly: yes.
3. Normal and reversed Y orientation is preserved: yes.
4. Explicit X/Y extents are preserved as deterministic cell centers: yes.
5. CLim and colormaps are preserved: yes, for linear scaled mapping.
6. Existing colorbar support integrates without duplication: yes.
7. `Profile='publication'` works unchanged: yes.
8. `m2t.exportSet` works unchanged: yes.
9. Generated TeX is deterministic: yes.
10. The renderer remains handle-free: yes.
11. Unsupported RGB and alpha are explicit: yes.
12. Pure PGFPlots is costly near 100x100 and impractical at 250x250 locally.
13. Windows Octave 11.3 is green; hosted Linux is configured but not yet run.
14. All local M2-M3.2 regressions are green.
15. Readiness follows from the final regression and hosted external gate.

CONDITIONAL GO FOR M3.4
