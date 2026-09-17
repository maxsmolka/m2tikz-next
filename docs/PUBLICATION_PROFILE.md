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
membership and geometry. Untiled figures use one common affine placement map
for axes, colorbars and figure-normalized arrows when fixed-size text needs
more physical room. This preserves their relative arrangement and ownership,
not necessarily the exact normalized source rectangles. Sufficiently padded
geometry is unchanged. Data-coordinate annotations remain in data coordinates.
Explicit tiled grids use the physical outer/per-cell gutter policy in
[TILED_LAYOUTS.md](TILED_LAYOUTS.md), preserving cells/spans and scientific
semantics while moving axes and their owned colorbars. Figure-space annotations
and cells too dense for the selected size fail that transform explicitly.
Default `Profile="none"` behavior is unchanged.

## Physical text gutters

Shrinking a page does not shrink the 10/9/8 pt typography. Keeping untiled
normalized rectangles unconditionally could leave less room than the title's
font plus PGFPlots title offset, while the fixed standalone page cropped it.
The profile now fits physical gutters before rendering, using the established
tiled typography policy (for example 8 + 10 + 8 = 26 TeX points above an axes
with a title). Label/tick roles and oriented colorbars reserve their own sides.
The transform solves for the largest common scale not exceeding one and the
smallest feasible translation; existing margins count toward the requirement.
It does not append page padding, change canonical width/height/aspect policy,
shrink text, move individual manual axes independently or scale scientific data.
Fewer than two tick-font sizes of remaining plot width/height fails explicitly
with `M2T:PROFILE_GEOMETRY_INVALID` before product generation.

This is a bounded layout policy, not an arbitrary-TeX text measurement engine.
Very long/custom text, dense/manual overlaps and user-authored annotations
still need visual review; runtime success checks do not claim to detect all
visual defects. The known short-title failure is locked by P01-P13 plus default
controls, actual glyph boxes, title/plot separation and physical PDF page sizes.
Run `runPublicationGeometryTests(out,true)` then
`python test/checkPublicationPdfGeometry.py <out>` (validation-only pdfplumber).

Current publication geometry evidence uses MATLAB R2026a Update 5 on Windows
and GNU Octave 11.3 on Linux. MATLAB compilation uses the documented Linux
LuaLaTeX bridge, not native Windows TeX. Native tiled/shared/dual-Y evidence is
MATLAB-specific; corresponding Octave cases are portable IR/renderer checks.
This supersedes the earlier Update 4 publication-specific qualification;
historical broader capability records are not relabeled.

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
