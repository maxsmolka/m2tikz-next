# ADR-0028: Lower axes-owned outside legends

Status: accepted for the v0.8.2 acceptance patch after v0.8.1.

## Context and scope

The user needs the already-supported horizontal/two-row legend layout below
an axes as well as above it. This is a narrow continuation of ADR-0026, not a
new plot family or public API expansion. Immutable v0.8.1 still rejects it.

## Decision

Normalize `southoutside` to additive FigureIR v2 `south_outside` with explicit
orientation/columns. Retain the one-logical-2-D ownership boundary, including
supported single-cell tiled and dual-Y cases. Preserve linked entry order,
column count, box state and all caller/scientific state. Vertical multicolumn,
east/west/manual/shared/multi-axes/3-D outside layouts remain unsupported.

Anchor the matrix below the axes and reserve physical clearance for X ticks
and the optional X label. Dual-Y legend-only overlays carry the original
X-label presence so removing duplicate labels does not remove that clearance.
Publication profiles add lower row-count space to existing bottom gutters.
No-profile exports keep source size/geometry unchanged and require sufficient
source margin. Existing actual matrix/page bounds reject overflow; do not
shrink fonts/columns, widen pages or silently restyle the source to make it fit.

Historical IR defaults/canonical bytes and upper-legend TeX remain unchanged.
Older implementations cannot read the new enum value; no forward compatibility
with those readers is claimed. Public APIs, schema numbers and manifests are
unchanged. This is not arbitrary TeX text measurement/collision resolution;
custom or multiline labels and other lower decorations need visual review.

## Acceptance

Native MATLAB reads six linked series in explicit order with three columns.
Real public exports cover no profile and 85/170 mm, retaining caller state.
Portable/native compilation covers two rows, ragged rows, X-label variants,
one-cell tiled and dual-Y ownership, plus source-margin/width overflow failures.
Check actual PDF glyph/page bounds, row/column order, plot/X-label separation
and physical dimensions, then visually inspect output. R2026b bridge evidence
does not qualify the external R2022a/native Windows MiKTeX environment.
