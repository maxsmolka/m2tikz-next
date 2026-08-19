# ADR-0005: Layout and geometry

- Status: Accepted
- Date: 2026-08-09
- Scope: FigureIR and AxesIR version 2

## Context

M2.1 intentionally rejected multiple axes because the IR had identity and order
but no renderable placement. M2.2 must preserve subplot-style, manually placed,
unequal, and overlapping Cartesian axes without encoding MATLAB `subplot`,
Octave internals, or future `tiledlayout` classes in the renderer.

Logical layout and physical geometry are related but not equivalent. A 2-by-2
grid expresses author intent and future relationships; a normalized rectangle is
what a renderer needs. Manual axes and overlays may have no useful grid intent,
while the same logical grid can be rendered with different gaps and margins.

## Decision

IR version 2 gains both layers additively.

Physical geometry is authoritative:

```text
FigureIR.size = [width height] points, or [] for backend auto-size
AxesIR.placement = {x, y, width, height} normalized to FigureIR
AxesIR.overlayOf = earlier axes ID, or empty
```

PostScript points are a renderer-neutral physical unit with deterministic JSON
values and direct TeX conversion. They are not publication target dimensions.
The runtime reader obtains them from print-oriented figure geometry rather than
storing operating-system pixels. An empty size preserves the pre-M2.2 v2
single-axes backend-default behavior for old JSON.

`placement` is the axes plotting rectangle represented by the runtime `Position`
property after conversion to normalized figure units. It is not `OuterPosition`
and does not include labels, titles, tick-label extents, or legends. `TightInset`
is retained only as a possible reader/validation hint; it is not serialized and
M2.2 does not implement a decoration layout solver. Positive rectangles inside
the normalized figure domain are required, but rectangles may overlap.

Logical layout is optional metadata:

```text
LayoutIR
  kind: freeform | grid
  rows, columns
  cells[]: axesId, row, column, rowSpan, columnSpan
```

`freeform` has no cells. `grid` uses one-based, top-to-bottom rows and
left-to-right columns. Reader inference is conservative and based on aligned
physical rectangles because portable `subplot` intent metadata is not available
across MATLAB and Octave. Physical placement remains authoritative even when a
grid is present. A future `tiledlayout` reader can populate the same metadata
directly without changing renderers.

Axes array order is the deterministic back-to-front render order. IDs are unique.
An `overlayOf` relationship references an earlier, physically overlapping axes;
it records relationship without merging coordinate systems. Series, ticks, text,
and legends remain owned by their axes. Figure-wide/shared legends are outside
M2.2 and fail with `M2T2:E010:UnsupportedSharedLegend`.

The PGFPlots backend emits multiple `axis` environments in one `tikzpicture`.
For figures with physical size, each uses `at`, `anchor=south west`, `width`,
`height`, and `scale only axis`. The figure size supplies the coordinate canvas;
axes placement supplies the plot rectangle. The renderer never queries runtime
objects or logical layout APIs.

## Compatibility

The fields are additive under ADR-0003. Missing v1/v2 layout fields normalize to
`size=[]`, `layout=freeform`, full default placement, and no overlay relationship.
That combination preserves old backend auto-sizing and rendering. New runtime
reads carry explicit size and placement. No IR version increment is required.

Invalid normalized geometry has the distinct diagnostic
`M2T2:E009:InvalidPlacement`. Unsupported shared/unowned legends use E010. E006
remains available for future unsupported layout constructs but no longer rejects
ordinary multiple 2-D axes.

## Consequences

Manual geometry and overlays are lossless within normalized plotting-rectangle
precision, JSON is runtime-independent, and alternative renderers can use either
physical rectangles or logical intent. Page decoration bounds can still differ
from legacy because text metrics and `TightInset` are not solved. MATLAB meanings
of `Position`, `OuterPosition`, `ActivePositionProperty`/`PositionConstraint`,
HG2 order, legend association, and print size are **MATLAB VALIDATION REQUIRED**.
