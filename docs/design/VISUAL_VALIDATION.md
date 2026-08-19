# Visual validation design

## Goal

Compare the source MATLAB/Octave figure with the PDF produced from generated
TikZ/PGFPlots without treating renderer noise as a scientific difference. M1B
prepares the contract only; it does not implement a pixel-diff service.

## Proposed pipeline

1. Freeze figure size, background, DPI, view/camera, axes limits, and random seed.
2. Render the native figure to lossless PNG and export standalone TikZ.
3. Compile with the review engine (prefer LuaLaTeX) and rasterize the PDF at the
   same physical size and DPI.
4. Normalize canvas, crop using measured page/axes bounding boxes, and retain an
   alpha/background mask.
5. Compare several signals rather than one global pixel threshold.
6. Store inputs, renderers/versions, intermediate PNGs, diff maps, metrics, and a
   human approval record.

## Signals and tolerances

- **Bounding boxes:** compare plot area, legends, labels, and page bounds before
  pixels. Large shifts fail even if colors look similar.
- **Pixel difference:** useful for missing series or gross color changes, but
  edges should receive a small distance tolerance.
- **SSIM-like similarity:** useful for overall structure and raster/image plots;
  it must not hide local scientific deviations.
- **Data-region masks:** compare lines, markers, surfaces, and image content more
  strictly than text/anti-aliased edges.
- **Text/layout:** OCR is not the primary oracle. Compare extracted expected
  labels semantically, then allow modest glyph and baseline differences.
- **Manual approval:** required for new plot families, borderline metrics, font
  substitutions, and any changed scientific data representation.

## Sources of benign variation

Anti-aliasing, hinting, fonts, native graphics toolkits, PDF rasterizers, DPI,
device pixel ratios, and TeX engine metrics can change edge pixels and small
layout offsets. All tools and fonts must therefore be recorded. Comparison should
use fixed DPI, linear-light or explicitly documented color space, edge-aware
tolerance, and separate text/data masks.

## Scientific safeguards

Global similarity alone is unsafe: a missing short segment can have little impact
on a large white canvas. The validation must additionally check series count,
coordinate ranges, extrema, discontinuities, axis direction/scales, color limits,
legend mapping, and annotations. Any automatic approval must explain which
semantic and visual gates passed.
