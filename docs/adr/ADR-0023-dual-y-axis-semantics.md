# ADR-0023: Dual Y-axis semantics

- Status: Accepted
- Date: 2026-09-15
- Scope: M6.4 bounded native MATLAB yyaxis

## Decision

Keep one axes and one layout cell for two Y rulers sharing a numeric X ruler.
Add optional `dualY` metadata and explicit per-series `yAxis` membership to v2.
The ordinary Y fields remain authoritative for the left side, avoiding a
duplicate interpretation of old v2 axes. Right-side state and both ruler colors
are explicit. Missing membership is invalid when dual metadata is present.

Use documented active-side `Children` queries, compare their union against
`allchild`, and restore active state even on failure. Do not infer membership
from colors/ranges/names or an unavailable hidden axis-index property. Resolve
legend series through capability-checked native links. Unavailable or ambiguous
links produce a structured failure. No live handles enter FigureIR.

Render coincident coordinate systems with identical X/physical geometry and
independent Y state. Emit each scientific table exactly once in IR drawing
order, using transparent axis layers, then draw the explicit legend. This
avoids scientific rescaling and cross-side paint-order changes. The cost in
axis setup grows with series count; data volume is not multiplied.

Reuse explicit tiled profile slots, adding right-side physical gutters. A
single untiled dual axes uses one explicit profile slot; its original logical
layout is retained. Multiple manual axes and figure-space annotation fitting
are not guessed. Shared ColorMappingIR/colorbar ownership is unchanged.

## Consequences and gates

The API remains unchanged, old ordinary v2 JSON retains its defaults, and the
renderer remains runtime-neutral. Native MATLAB reader/workflow evidence is
mandatory and separate from portable Octave IR and real TeX/PDF evidence.
Unsupported child types, hidden membership and uncommon ruler presentations
fail before scientific products are written. See the complete bounded
[dual-axis contract](../DUAL_Y_AXES.md).
