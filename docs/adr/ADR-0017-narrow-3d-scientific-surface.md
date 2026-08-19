# ADR-0017: Narrow 3-D scientific surface

## Status

Accepted.

## Decision

Support a narrow orthographic Cartesian 3-D contract with additive FigureIR v2
fields. `m2t2.surface` stores equal finite X/Y/Z/C matrices with scalar mapping,
interpolated opaque faces, and hidden edges. `m2t2.line3` stores coordinate
triples. `m2t2.patch3` stores one finite opaque triangle. Axes store view,
projection, and aspect information; ColorBarIR remains authoritative.

Native Patch3 recognition requires a positive capability/ownership signature.
Arbitrary patches and groups remain unsupported. PGFPlots rendering uses
native `addplot3` primitives and no runtime handle, screenshot, or raster
fallback.

## Consequences

Synthetic public IR fixtures cover surface, Line3, Patch3, colorbar, JSON,
profiles, determinism, and diagnostics. Generic 3-D scenes, mesh, scatter3,
contour3, perspective, lighting, materials, and transparency are not claimed.
