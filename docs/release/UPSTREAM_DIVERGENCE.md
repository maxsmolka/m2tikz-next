# Upstream divergence

m2tikz-next retains the matlab2tikz legacy exporter while adding an experimental
modernization path. Major additions include:

- a normalized, versioned intermediate representation with JSON migration and
  deterministic replay;
- runtime-isolated readers and a graphics-handle-free renderer;
- stable IDs, explicit ownership/references, and structured diagnostics;
- line, scatter, and errorbar series in the new path;
- multiple axes, subplot-style/freeform placement, overlays, and physical figure
  geometry;
- explicit colorbar, shared-legend, and shared-label IR/renderer nodes;
- layered reader/IR/renderer tests, legacy semantic comparisons, TeX matrices,
  PDF/raster geometry validation, and performance measurements.

This is not full replacement coverage. The new path does not yet provide image
or heatmap series rendering, tiled-layout reading, `yyaxis`, polar figures, the
legacy 3-D feature surface, annotations, backend selection, or a stable
user-oriented M3 workflow. Shared figure elements are validated in IR/renderer;
their MATLAB runtime discovery remains unvalidated.

The inherited `matlab2tikz(...)` API is preserved and is not silently redirected.
The experimental modernization entry point is `m2t2.export(...)`. MATLAB
compatibility must not be claimed until the repository's MATLAB validation plan
has been executed successfully on selected releases.
