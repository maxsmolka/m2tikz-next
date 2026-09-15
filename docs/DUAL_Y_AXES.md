# Dual Y axes

M6.4 adds a bounded native MATLAB `yyaxis` contract. It is an unreleased
development feature, not a claim about the released 0.5.0 package or native
Octave support. The public calls and options are unchanged.

## Supported contract

- One shared numeric X ruler, automatic aspect ratios and a Cartesian 2-D view.
- Left/right line and rich scatter series, including scalar-mapped color and
  per-point size/color under the existing scatter contract.
- Independent increasing Y limits, linear/log scales and normal/reverse
  directions. Log limits and finite log-domain coordinates must be positive;
  NaN gaps retain the existing line semantics.
- Independent manual major ticks/text and Y labels, with each side's RGB color.
  Automatic ticks remain renderer-selected as in single-axis exports. Linear
  minor ticks are off; logarithmic minor ticks use the automatic standard grid.
- Shared X labels/ticks, title, box and X grid; Y grid follows the left ruler.
- Axes-owned legends with actual runtime series links, including explicit
  selection and reordered labels. Symbol ownership never follows label text.
- Axes-owned colorbars sharing the axes ColorMappingIR, including mapped
  scatter on the right side. A colorbar is not a third Y ruler.
- Fixed tiled-layout interaction under [TILED_LAYOUTS.md](TILED_LAYOUTS.md).
- Publication widths 85/170 mm, including figure sets. Single untiled axes and
  explicit tiled cells reserve physical right-label/tick gutters. Dense grids
  fail instead of shrinking scientific typography without permission.
  East colorbars use an 8 pt body with separate label/tick space at both widths.

```matlab
fig = figure;
ax = axes(fig);
yyaxis(ax,'left');
plot(ax,1:3,[1 3 2],'DisplayName','Response');
ylabel(ax,'Response');
yyaxis(ax,'right');
plot(ax,1:3,[10 100 1000],'DisplayName','Rate');
set(ax,'YScale','log');
ylabel(ax,'Rate');
legend(ax,'show');
result = m2t.export(fig,'dual','Profile','publication');
```

## Ownership and representation

MATLAB's documented `Children` property contains only the active side;
`allchild` exposes both. The reader selects each side with `yyaxis(ax,side)`,
reads its state, and restores the initially active side through cleanup on
success and failure. It compares the two complete child lists with `allchild`;
unknown, hidden-handle or multiply owned content fails rather than vanishing.
The source runtime's back-to-front `allchild` order is retained, not assumed to
be global creation order. See [MathWorks yyaxis documentation](https://www.mathworks.com/help/matlab/ref/yyaxis.html).

FigureIR v2 gains an optional axes `dualY` structure. Existing `ylim`, `yscale`,
`ydirection`, `yticks` and `ylabel` describe the left side. `dualY.leftColor`
and `dualY.right.{limits,scale,direction,ticks,label,color}` make the second
coordinate system explicit. Every contained series requires `yAxis=left|right`.
An absent side on a dual axes is ambiguous and invalid; old ordinary axes are
unchanged. JSON normalization preserves these fields without a schema bump.

The handle-free renderer decorates the two coincident coordinate systems,
renders data in IR order using the corresponding system, and draws the linked
legend last. It never rescales right Y data into left coordinates. Extra
transparent axis layers preserve cross-side drawing order. Axis setup grows
with series count and small style definitions may repeat; coordinate tables
are not duplicated. Large-series-count performance remains an M6.6 measurement.

## Explicit limits

Non-line/scatter children (including text annotations and bars), ambiguous
hidden-handle membership, unavailable legend links, reversed legend direction,
manual aspect ratios, unrelated overlaid axes, nonnumeric X, nonstandard minor
ticks, rotated ticks, exponent notation or custom tick formats, hidden rulers,
and independently recolored tick/label text are outside this slice.
`PlotChildren` is capability-checked for native legend ownership; unsupported
runtime representations fail rather than use positional guesses.

Manual/multiple untiled dual axes cannot use the publication gutter transform;
use an explicit supported tiled layout. Figure-space annotations cannot be
carried through that transform. General font-metric matching and arbitrary
label lengths/grid density are not promised. Review publication PDFs.

Reader failures use E059 (ambiguous membership), E060 (unsupported dual state),
or E061 (invalid shared X/aspect state). Invalid portable metadata and nonpositive
log domains fail IR validation (E003). Profile geometry uses
`M2T:PROFILE_GEOMETRY_INVALID`. All occur before successful output production.

## Validation lanes

Native MATLAB R2026a Update 5 on Windows tests cover ownership, active-side
restoration, reordered legends, independent ticks/scales/directions, mapped
scatter/colorbars, tiled layouts, profiles and unsupported-content failure.
Public native workflows require an actual LuaLaTeX compiler; current evidence
uses a temporary bridge to Linux TeX Live 2025/Debian, not native Windows TeX.
Portable Octave 11.3 tests validate only handle-free IR, JSON and TeX rendering.
Compiled native and portable PDFs are additionally reviewed visually.

Run `runM64DualYMatlabTests`, `runM64DualYWorkflowTests`,
`runM64DualYIrTests`, and `runM64DualYTexTests` from `test` as appropriate to
each runtime. The historical broad wording remains unchanged:
Validated with MATLAB R2026a Update 4 on Windows.

See [ADR-0023](adr/ADR-0023-dual-y-axis-semantics.md),
[support](SUPPORT.md) and [diagnostics](design/DIAGNOSTICS.md).
