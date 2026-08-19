# ADR-0015: Semantic grouped bars

## Status

Accepted.

## Decision

Model every matrix column as an axes-owned `m2t2.bar` series. Peer series share
a stable group ID, ordered indices/count, numeric categories, width, and
baseline. Values, visibility, constant face/edge style, and display names are
explicit.

Reader recognition requires the complete semantic property and ownership
contract; arbitrary groups and patches are not bars. The handle-free renderer
computes group geometry from IR and emits vector paths in axis coordinates.

## Consequences

Vertical grouped bars, including mixed signs, compose with legends, multiple
axes, figure sets, JSON replay, and publication profiles. Stacked/horizontal
bars, categorical arrays, mapped/per-bar colors, histograms, and ambiguous
compounds remain explicit diagnostics.
