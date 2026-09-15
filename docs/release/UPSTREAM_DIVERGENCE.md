# Upstream divergence

m2tikz-next retains the matlab2tikz legacy exporter while adding a modern
scientific-export path. Major additions include:

- a normalized, versioned intermediate representation with JSON migration and
  deterministic replay;
- runtime-isolated readers and a graphics-handle-free renderer;
- stable IDs, explicit ownership/references, and structured diagnostics;
- line, scatter, errorbar, grouped-bar, traditional boxplot, scalar-image, and
  narrow scientific 3-D series in the new path;
- multiple axes, subplot-style/freeform placement, overlays, and physical figure
  geometry;
- explicit colorbar, shared-legend, and shared-label IR/renderer nodes;
- layered reader/IR/renderer tests, legacy semantic comparisons, TeX matrices,
  PDF/raster geometry validation, and performance measurements.

Development functionality additionally includes rich per-point scatter,
bounded RGB/alpha images, fixed MATLAB tiled layouts, explicit dual Y axes,
and bounded rich scatter3/wire meshes with explicit camera and ordering limits.
These are not retroactive claims about the released 0.5.0 package.
This is not full replacement coverage: dynamic/nested layouts, unsupported
dual-axis variants, polar figures, general 3-D scenes, broad annotation families
and other [documented gaps](../SUPPORT.md) remain unsupported. Shared figure
elements have narrower runtime coverage than their IR/renderer model.

The inherited `matlab2tikz(...)` API is preserved and is not silently
redirected. The public modern entry points are `m2t.export(...)` and
`m2t.exportSet(...)`; `m2t2.*` remains internal/experimental. MATLAB validation
retains the historical MATLAB R2026a Update 4 on Windows boundary, with separate
Update 5 evidence for later bounded additions in the [matrix](../MATLAB_VALIDATION_MATRIX.md).
