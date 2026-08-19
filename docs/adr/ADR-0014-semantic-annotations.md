# ADR-0014: Semantic annotations

## Status

Accepted.

## Decision

Represent axes-owned 2-D text and figure-owned arrow/double-arrow annotations
as explicit IR. Text stores ownership, data coordinates, interpreter,
alignment, rotation, font, color, and visibility. Arrows store normalized
endpoints, stroke, color, and explicit heads.

Recognition is capability- and ownership-based. Empty runtime helper panes may
be ignored only when positively identified; unsupported or mixed children fail
explicitly. The renderer is handle-free, deterministic, and vector-native.
Labels and titles remain axes semantics rather than annotations.

## Consequences

Annotations work through `m2t.export`, `m2t.exportSet`, JSON replay, and
publication profiles. Text in unsupported units, 3-D text, text arrows,
rectangles, ellipses, text boxes, braces, and arbitrary groups remain outside
the contract. No screenshot or legacy fallback exists.
