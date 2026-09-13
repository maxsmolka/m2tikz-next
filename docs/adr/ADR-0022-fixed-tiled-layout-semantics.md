# ADR-0022: Fixed tiled layout semantics

- Status: Accepted
- Date: 2026-09-13
- Scope: M6.3 bounded native MATLAB tiled layouts

## Decision

Extend ADR-0005's existing logical grid and resolved physical geometry model.
For one whole-figure fixed native layout, read grid/Tile/TileSpan/indexing
directly, assign axes IDs in physical row-major cell order, and retain resolved
runtime rectangles. Never run conservative rectangle inference for this path.
Reject ambiguous/dynamic/nested/outer-tile ownership before export.

The optional LayoutIR.tiled structure contains arrangement=fixed,
indexing=rowmajor|columnmajor, spacing=loose|compact|tight,
padding=loose|compact|tight and geometry=resolved-runtime. Every axes must own
exactly one nonoverlapping logical cell. Older v2 grids without this structure
remain valid; no reinterpretation of old metadata or version bump is required.

Reuse layout-owned SharedLabelIR and axes-owned legends/colorbars. The existing
renderer sees only FigureIR, placements and semantic text roles. Native runtime
geometry finalization runs without user callbacks and readers restore units.
This is a snapshot of a fixed layout, not a new runtime layout engine.

Publication typography has physical sizes, so uniformly scaling the canvas alone
can collide with shared labels. For explicit tiled metadata, the profile reserves
outer physical gutters, applies one affine rectangle transform to axes/colorbars,
and positions shared labels within the margins. Data and cell relationships are
unchanged. Figure-space annotations are not safely related to the moved axes and
therefore fail this optional transform. Untiled profile behavior is unchanged.

## Evidence-driven limits

The first 85 mm profile collided at the shared Y label. The gutter transform
corrected it and was visually rechecked. Zero tile spacing produced overlapping
tick labels; none is explicitly unsupported rather than silently hiding labels.
General decoration fitting, arbitrary grid density, shared outer legends and
font-metric matching remain outside this slice.

Native MATLAB evidence is mandatory and recorded separately from portable
Octave IR, compiler, and visual evidence. A portable fixture cannot establish
native tiledlayout support. See [the contract](../TILED_LAYOUTS.md).
