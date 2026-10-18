# ADR-0026: Horizontal and upper outside axes legends

## Status

Accepted for the post-v0.8.0 external-acceptance correction.

## Context

An external acceptance figure needs an existing horizontal six-column legend
above its axes. Changing that source layout would lose requested presentation.
This is a narrow existing-decoration gap; real figures/data remain private,
and synthetic labels/lines provide public regression coverage.

## Decision

- Add optional LegendIR `layout.orientation`/`layout.columns`, `north_outside`
  and frame suppression. Absent fields retain old constructor/default/canonical
  bytes. FigureIR stays v2; no scientific payload, ownership or public API change.
- Preserve semantic entry order and actual series links; horizontal entries
  fill rows left to right with the requested column count.
- Limit outside placement to one logical 2-D axes, including one-cell tiled
  and supported dual-Y configurations. Keep other outside/manual/3-D/multi-axes
  and vertical multicolumn variants explicitly unsupported.
- Reserve profile space without source handles or guessed character widths.
  Measure the actual TeX matrix against the page and reject overflow using
  the existing compiler diagnostic. Never silently shrink or crop output.

## Consequences

A long six-column legend may require the explicit 170 mm preset. Overflow can
leave TeX/a log but no accepted PDF, under the existing output lifecycle.
Old one-column goldens remain unchanged. Older implementations cannot replay
new presentation semantics; no forward-compatibility promise is added.
R2026b evidence does not replace the tester's separate R2022a acceptance run.
