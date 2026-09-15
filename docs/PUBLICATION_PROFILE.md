# Publication profile

The opt-in publication profile provides deterministic physical sizing and
typography for publication-ready PGFPlots output. Its API identifier is
`Profile="publication"`.

## Canonical sizes

| Preset | Width |
|---|---:|
| `single-column` | 85 mm |
| `double-column` | 170 mm |

The profile uses 10 pt titles, 9 pt base and axes-label text, and 8 pt tick and
legend text. Colorbar labels use 9 pt and colorbar ticks use 8 pt. Figure aspect
ratio is preserved between 0.45 and 1.25; values outside that interval are
clamped with an explicit diagnostic.

## Preservation policy

The profile changes presentation only. It preserves data, axes limits, series
order, line widths, marker sizes, user-authored annotation sizes, legend
membership and geometry. Untiled figures retain relative axes/colorbar geometry.
Explicit tiled grids use the physical outer/per-cell gutter policy in
[TILED_LAYOUTS.md](TILED_LAYOUTS.md), preserving cells/spans and scientific
semantics while moving axes and their owned colorbars. Figure-space annotations
and cells too dense for the selected size fail that transform explicitly.
Default `Profile="none"` behavior is unchanged.

```matlab
result = m2t.export(gcf, 'figure', ...
    'Profile', 'publication', ...
    'Width', 'single-column');
```

The public synthetic acceptance suite covers line, legend, scalar-image and
colorbar, annotation, multiple-axes, grouped-bar, boxplot, and narrow 3-D
figures. Run it with:

```matlab
addpath('test');
runPublicationProfileTests(fullfile('.audit', 'publication-profile'));
```

The public-safe scorecard is
[`audit/publication-profile-acceptance.json`](../audit/publication-profile-acceptance.json).
