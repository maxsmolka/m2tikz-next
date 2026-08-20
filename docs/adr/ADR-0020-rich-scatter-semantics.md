# ADR-0020: Explicit rich-scatter semantics

## Status

Accepted for M6.1.

## Context

Scatter arrays are ambiguous without their semantic mode. Marker source size is
an area in points squared, whereas PGFPlots `mark size` is a radius. Scalar
color values also belong to the axes color mapping, while explicit RGB does not.
Flattening any of these distinctions would change scientific meaning.

## Decision

ScatterIR v2 gains additive `sizeMode`, `colorMode`, `colorData`, `edgeMode`,
`edgeColor`, `faceMode`, and `faceColor` fields. `markerSize` stores normalized
marker diameter: the reader computes `sqrt(SizeData)`, and the renderer emits
half that value as PGFPlots radius. A mode makes scalar and vector fields
unambiguous. `scalar_mapped` retains point values and uses the owning axes CLim
and colormap; `per_point_rgb` retains RGB rows and creates deterministic symbolic
scatter classes. Edge and face roles are independently `none`, `constant`, or
`data`. Per-point sizes are emitted as consecutive, source-order-preserving plot
segments with explicit constant PGFPlots radii. This avoids relying on a
LuaLaTeX/PGFPlots per-point marker-size hook that can compile without applying
the requested sizes.

Old v2 documents without the additive fields normalize to constant size,
constant RGB edge, and no face, preserving their existing output contract. The
schema version remains 2. Readers use observable capabilities, and renderers use
only normalized IR.

## Consequences

Size ratios remain scientifically meaningful, point ordering and color-class
ordering are deterministic, and scalar scatter shares ColorbarIR with images and
surfaces. Nonopaque alpha, 3-D scatter, malformed arrays, and edge/face modes
outside the evidence-backed subset fail with focused diagnostics. No public API
option is introduced and no fallback or downsampling occurs. Many unique sizes
increase the number of PGFPlots commands; M6.1 deliberately prefers correctness
over implicit size quantization.
