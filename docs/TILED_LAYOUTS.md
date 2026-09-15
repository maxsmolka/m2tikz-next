# Fixed tiled layouts

M6.3 supports one visible MATLAB `tiledlayout(rows,columns)` occupying the whole
figure. Normal `nexttile`, explicit tile numbers, rectangular TileSpan and both
row-major and column-major indexing are normalized to deterministic top-to-bottom,
left-to-right axes order. Empty cells are retained as empty space, not filled.

```matlab
f = figure;
t = tiledlayout(f, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
plot(nexttile(t, 1), 1:3);
plot(nexttile(t, 2, [2 2]), [1 2 3], [1 4 2]);
title(t, 'Experiment');
xlabel(t, 'Time');
ylabel(t, 'Response');
result = m2t.export(f, 'figures/tiled', 'Profile', 'publication');
```

## Supported slice

- Fixed positive row/column counts; nonoverlapping in-bounds rectangular cells.
- `TileSpacing`: `loose`, `compact`, `tight`. `Padding`: `loose`, `compact`, `tight`.
- Shared title/X/Y text with existing literal/TeX/LaTeX semantics and standard
  horizontal title/X label and vertical Y label orientation.
- Existing axes-owned legend modes and colorbars remaining in their owner tile.
- Existing supported scientific series, image planning, publication profiles
  and figure-set delegation remain subject to their separate contracts.

The reader resolves deferred geometry with `drawnow nocallbacks`, reads explicit
tile metadata, and restores temporarily changed units. It does not infer tiled
ownership from rectangles or mutate scientific data. The completed runtime
plotting rectangles are authoritative for source-size output. Shared labels use
semantic role anchors, not MATLAB font-metric replication. Custom typography is
subject to the existing renderer/profile text contract.

LayoutIR remains a `grid` with explicit cells and adds optional `tiled` metadata:
fixed arrangement, source indexing, spacing, padding and resolved-runtime
geometry provenance. Older grids without this metadata retain their behavior.
The renderer consumes only handle-free placements and existing shared-label
nodes; it has no MATLAB tiled-layout API calls or pixel-position guesses.

## Profiles and sets

The 85/170 mm publication profile reserves physical outer and per-cell text
gutters, including simultaneous local and shared labels. The explicit grid
determines equal cell slots and spanning rectangles. Source spacing/padding
choices map to 2/4/8-point tight/compact/loose gaps and padding. Colorbars follow
an affine transform relative to their owning axes, with space reserved on the
appropriate side. Cell order, spans and scientific series are unchanged.
Shared labels receive physical-margin anchors. This is an explicit opt-in profile layout
policy, not source geometry inference or data reduction. Unprofiled output
retains runtime rectangles. It is not a general text-measurement/layout solver;
long labels and dense grids still require visual review and a suitable size.
Cells with insufficient plotting area, manual colorbar placement and unsupported
decoration ownership fail with `M2T:PROFILE_GEOMETRY_INVALID`.
Figure-space annotations are rejected for this gutter transform because their
relationship to moved axes cannot be inferred safely. Axes-data text retains
its explicit coordinate system.

`m2t.exportSet` uses the same per-figure pipeline; no set-specific tiled renderer
or option is introduced. Repeated successful builds retain deterministic
manifest and logical layout metadata.

## Explicitly unsupported

Dynamic `flow`/vertical/horizontal arrangements, nested or multiple layouts,
mixed tiled/manual axes, partial-figure layout containers, invalid/overlapping
spans, layout subtitles, custom shared-label rotation, and outer or multi-tile
legend/colorbar placement fail explicitly. `TileSpacing='none'` is rejected:
visual testing showed overlapping tick labels, and M6.3 does not silently hide
them or invent new gaps. Unsupported axes/series still fail through the normal
reader diagnostics. `yyaxis` remains outside M6.3.

`M2T2:E056:UnsupportedTiledLayout`, `M2T2:E057:InvalidTileCell` and
`M2T2:E058:UnsupportedTileDecoration` distinguish these boundaries. Public
analysis fails before output creation; it does not report partial support.

## Evidence

New native evidence: MATLAB R2026a Update 5 on Windows, 28 focused reader/profile/
negative cases and three real workflow/set cases. The workflow cases use a local
bridge to Linux LuaLaTeX; this is not native Windows TeX evidence. Nineteen
native-generated TeX fixtures and four portable fixtures compile separately.
Portable Octave IR/renderer tests do not imply native Octave tiledlayout parity.

The existing broader evidence statement remains:

Validated with MATLAB R2026a Update 4 on Windows.

See the [M6.3 report](../M2TIKZ_NEXT_M6_3_MODERN_TILED_LAYOUTS_REPORT.md),
[layout ADR](adr/ADR-0022-fixed-tiled-layout-semantics.md), and MathWorks'
[layout properties](https://www.mathworks.com/help/matlab/ref/matlab.graphics.layout.tiledchartlayout-properties.html)
and [nexttile reference](https://www.mathworks.com/help/matlab/ref/nexttile.html).
