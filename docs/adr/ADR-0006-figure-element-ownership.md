# ADR-0006: Figure-element ownership and references

- Status: Accepted for M2.3
- Date: 2026-08-09

## Context

The M2.2 tree expresses `Figure -> Axes -> Series` and axes-owned legends. A
colorbar is not a data series or an ordinary axes: it displays a scalar-to-color
mapping owned by data axes, has independent physical geometry, and may be shared.
Likewise a combined legend or shared label belongs to a figure or logical layout.
Runtime handles and MATLAB class names cannot cross the reader boundary.

## Decision

FigureIR v2 gains an additive `elements` cell array. Each item is a small
discriminated node, not a union struct with unrelated empty fields:

```text
FigureIR.elements[]
  m2t2.colorbar
  m2t2.legend
  m2t2.sharedlabel
```

Every element has a stable `id` and an owner reference:

```text
owner = { kind: axes | layout | figure, id: stable-id }
```

The reserved root IDs are `figure` and `layout`; axes owners use existing axes
IDs. References are validated after the complete axes array is known. Missing or
crossed references fail with `M2T2:E012:InvalidFigureElementReference`.

ColorbarIR is an explicit display node with owner, `associatedAxesIds`, physical
placement, logical location, orientation, direction, scale, limits, ticks, and
label. Its placement is the authoritative normalized figure rectangle. Location
is metadata and never reconstructs geometry.

AxesIR owns `colorMapping = {limits, scale, colormap}`. A colorbar displays this
mapping; it does not own or mutate it. Every associated axes must expose the same
limits and scale. An axes-owned colorbar must include its owner among the
associated axes. Unsupported relationships fail with
`M2T2:E011:UnsupportedColorbarOwnership`.

The existing axes-owned LegendIR remains unchanged. Figure-level `m2t2.legend`
entries contain `{axesId, seriesId, text}`, permitting stable references across
axes without changing old legend semantics. Shared labels contain role, owner,
text, and optional physical placement; they are never represented as dummy axes.

## Renderer strategy

Colorbars render as dedicated, handle-free PGFPlots display axes. This keeps
manual geometry and shared ownership independent from any one plotted axes.
Attaching `colorbar` to the owning data axis was rejected because it cannot
faithfully express arbitrary placement or one scale associated with multiple
axes. Shared legends use a dedicated legend-only PGFPlots environment, and
shared labels use TikZ nodes.

## Compatibility

This is an additive version-2 change under ADR-0003:

- missing `FigureIR.elements` becomes `[]`;
- missing `AxesIR.colorMapping` receives the historical neutral default;
- v1, pre-M2.1 v2, M2.1 v2, and M2.2 v2 remain loadable;
- existing axes-owned legends are not migrated.

Figure elements require explicit FigureIR point size because their normalized
physical placement cannot be resolved under backend auto-size.

## Runtime boundary and limitations

Octave represents colorbars as tagged axes. The reader identifies them before
ordinary axes, resolves their peer axes, reads actual normalized placement, and
normalizes automatic display limits from the peer axes `CLim`. This last rule is
necessary because Octave 11.3 reports automatic colorbar `Limits` in normalized
0-to-1 coordinates even when the axes `CLim` differs.

Image/heatmap data is not added as a series in M2.3. An image child is ignored
only while axes-owned color mapping is captured, so colorbar semantics can be
tested without claiming heatmap export. MATLAB `ColorBar.Axes`, layout ownership,
HG2 limits/ticks, and tiled-layout behavior remain MATLAB VALIDATION REQUIRED.

`tiledlayout`, `nexttile`, tile spans/spacing/padding, `yyaxis`, heatmap rendering,
polar, 3-D, and annotations are outside this decision. A detected multi-Y-ruler
axes is rejected as unsupported rather than silently treated as an overlay.

## Consequences

The renderer stays runtime-free and can render manual, independent, and shared
colorbars from the same node. Ownership is explicit and backend-neutral. Later
MATLAB readers can map tiled-layout owners onto the reserved layout reference
without a schema redesign. The cost is an additional validated reference pass
and a deliberate requirement for physical figure size when elements are present.
