# ADR-0024: Explicit bounded scientific 3-D

Status: accepted for the M6.5 development contract.

## Context

Scatter XYZ and wire topology can be expressed without runtime handles.
Camera modes and depth sorting cannot be inferred from plausible TeX output:
independently painted PGFPlots objects do not solve arbitrary scene occlusion.
The native MATLAB overlap probe distinguishes depth from child order.

## Decision

Extend rich scatter with a separate `m2t2.scatter3` discriminator and mandatory
Z. Add a conditional SurfaceIR wire mode with explicit RGB/style. Require
`sceneOrder` on new scenes; preserve old v2 narrow surface documents unchanged.
Allow one visible object in depth mode, or source-explicit child-order painting.
Sort scatter points stably in a local renderer copy while keeping data roles
attached. Reject camera states outside the tested orthographic mapping.
Do not turn default opaque/mapped native mesh into transparent wire geometry.

## Consequences

The supported boundary is useful but intentionally smaller than all MATLAB
3-D. No scene-wide depth renderer, projection approximation, reduction API,
new public option, whole-figure rasterization or legacy fallback is added.
Native object evidence, portable semantics, compilation and visual review are
distinct gates. See [the contract](../SCIENTIFIC_3D.md). This extends, rather
than rewrites the historical scope of [ADR-0017](ADR-0017-narrow-3d-scientific-surface.md).
