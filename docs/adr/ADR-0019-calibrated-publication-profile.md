# ADR-0019: Calibrated publication profile

## Status

Accepted.

## Context

Publication figures need deterministic physical dimensions and coherent
typography without changing scientific content or source-authored emphasis.

## Decision

Use the neutral API identifier `publication`. The canonical widths are 85 mm and
170 mm. Titles use 10 pt, base and labels 9 pt, and ticks and legends 8 pt.
Line, marker, annotation, legend, colorbar, and relative-layout semantics are
preserved. Aspect ratio is clamped only outside 0.45 to 1.25 with diagnostics.

## Evidence

Redistributable synthetic fixtures cover ordinary and dense lines, legends,
images/colorbars, annotations, multiple axes, grouped bars, boxplots, and the
narrow 3-D contract. Compiled-width and determinism checks are public.

## Consequences

Callers select the profile explicitly and default exports remain unchanged.
