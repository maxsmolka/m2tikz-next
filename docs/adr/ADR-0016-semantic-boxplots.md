# ADR-0016: Semantic boxplots

## Status

Accepted.

## Decision

Normalize positively identified traditional vertical boxplot compounds into
BoxplotSeriesIR. Store ordered positions, whiskers, quartiles, medians,
outliers, styles, visibility, owner, and display name. Statistics come from the
runtime's resolved table and are never recomputed from samples.

Recognition requires semantic metadata, complete child roles, finite ordered
statistics, and supported styles. The handle-free renderer draws deterministic
axis-coordinate whiskers, bodies, medians, and every outlier.

## Consequences

Boxplots compose with LineIR overlays, legends, layouts, figure sets, profiles,
and JSON replay. Native runtime creation may require an optional statistics
package, but replay/rendering does not. Horizontal, notched, ambiguous,
incomplete, violin, and swarm variants remain unsupported without fallback.
