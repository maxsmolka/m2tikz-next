# ADR-0011: Explicit hybrid image backend

- Status: Accepted
- Date: 2026-08-12

## Context

The M3.3 PGFPlots matrix representation preserves scalar data and scientific
coordinates but scales linearly in TeX size and compile work. A 250x250 matrix
produced about 1.8 MB of TeX and required roughly 108 seconds in the original
measurement. Dense publication heatmaps need a compact representation without
silently degrading unrelated vector content.

## Decision

Keep `ImageBackend='vector'` as the public default and add explicit
`ImageBackend='hybrid'`. A handle-free render plan produces TeX plus zero or more
image assets. Only scalar ImageIR layers become lossless PNG; PGFPlots axes,
text, ticks, colorbars, legends, shared elements, and other supported series
remain vector.

PNG is portable, lossless, supported by LuaLaTeX, and byte-deterministic with
the validated Octave 11.3 encoder. One scalar cell maps to one pixel. The
renderer shares the vector backend's clamped discrete colormap index rule,
rounds selected RGB channels to 8-bit values, and uses alpha zero only for NaN.
FigureIR retains the original scalar matrix.

PGFPlots `addplot graphics` places the raster at half-cell edges derived from
uniform centers. Pixel rows/columns incorporate coordinate order and axes
direction so vector and hybrid orientation match. Profile size does not change
pixel dimensions.

Final assets use `<output-stem>-assets/image-0001.png` in stable render order.
The workflow manages only that dedicated directory: collisions are fail-safe;
explicit overwrite recreates it; compilation failures retain assets. ExportResult
adds render metadata. Manifest schema 1 gains additive backend and relative-
asset fields while `exportSet` continues to delegate to `m2t.export`.

## Consequences

- Dense compile cost moves from PGFPlots coordinate parsing to compact PNG
  generation.
- Reader and profile remain backend-unaware; the compiler never creates assets.
- Hybrid uniform-coordinate support is narrower than a future non-uniform mesh.
- Automatic backend planning remains a later evidence-driven decision.

## Rejected alternatives

- Full-figure screenshots: destroy vector scientific presentation.
- Silent size switching: changes representation without consent.
- Automatic downsampling: loses scalar cells.
- Legacy fallback: bypasses normalized diagnostics.
- JPEG: introduces compression artifacts.
- Renderer/runtime coupling: violates the handle-free boundary.
