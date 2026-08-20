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

This is not full replacement coverage. Tiled layouts, `yyaxis`, polar figures,
general 3-D scenes, broad annotation families, per-point scatter semantics, and
other documented gaps remain unsupported. Shared figure elements have narrower
runtime coverage than their IR/renderer model.

The inherited `matlab2tikz(...)` API is preserved and is not silently
redirected. The public modern entry points are `m2t.export(...)` and
`m2t.exportSet(...)`; `m2t2.*` remains internal/experimental. MATLAB validation
is limited to MATLAB R2026a Update 4 on Windows.
