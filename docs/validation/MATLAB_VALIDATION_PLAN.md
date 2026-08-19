# MATLAB validation plan

> Historical planning document. M4.1 executed the current-release lane with
> MATLAB R2026a Update 4 on Windows; see
> [the validation matrix](../MATLAB_VALIDATION_MATRIX.md) and the repository-root
> M4.1 report for current evidence. Earlier milestone statements below are
> retained as the decision record that preceded runtime access.

## Gate statement

MATLAB is not available in M1B. All Handle Graphics and projection changes are
therefore marked **MATLAB VALIDATION REQUIRED**. Passing Octave tests is not a
claim of MATLAB compatibility and no official version-support promise is made by
this plan.

## Conceptual version matrix

- One current MATLAB release with the current HG2 implementation.
- One older HG2 release representative of established scientific-publication
  environments.
- Optionally one legacy/HG1 release, only if the project later decides that HG1
  remains supported and a runnable environment can be maintained.

Exact releases and support policy must be decided separately based on available
CI/licensing, user population, and dependency/toolchain support.

## Required execution matrix

For every selected release:

- complete ACID suite with its approved environment-specific Golden table;
- M1A regressions (`M2T-RUNTIME-001` through `003`);
- M1B 3D regression scenarios (`M2T-RUNTIME-005`);
- standalone TeX matrix with pdfLaTeX and LuaLaTeX;
- end-to-end smoke and deterministic rerun;
- bar/grouped/stacked bar, area, and patch child/property behavior;
- vertical/horizontal colorbar and manual colorbar positioning;
- 3D line, surface, mesh, changed view, limits/aspect ratios, orthographic and
  explicitly documented perspective behavior, and manual camera properties;
- `tiledlayout`, `yyaxis`, `heatmap`, `polarplot`, `histogram`, `FunctionLine`,
  `FunctionSurface`, and Unicode text.

The last group may expose unsupported/new object types; the gate requires an
explicit support/diagnostic classification, not an invented implementation in
M1B.

## Evidence to retain

Record MATLAB release/build, OS, graphics renderer, locale, TeX versions, test
counts, diagnostics, generated TeX/hashes, compile logs/PDFs, and visual-review
decisions. Compare the public `ColorBar.Axes` path, old/new bar child selection,
and MATLAB's existing `view(axesHandle)` transform against pre-M1A behavior.

## Release rule

Architecture prototyping may proceed with this gate outstanding. A release or
public statement of MATLAB compatibility may not: all intended supported MATLAB
rows must complete with no unexplained product failure, and any approved output
change must have semantic and visual evidence.

## M2 line-IR prototype additions

For each selected MATLAB release, run the M2 reader and renderer suites as
separate gates. The reader gate must cover the ten fixtures `minimal`,
`multiple`, `styled`, `labels`, `display_name`, `log_x`, `log_y`, `nan_gap`,
`inf_gap`, and `empty`, plus an unsupported scatter object. Confirm the stable
`M2T2:E001:UnsupportedObject` identifier and that its message records type and
structural path. In particular, verify HG2 child ordering, label handles,
`DisplayName`, color values, line/marker vocabulary, empty `line` behavior, and
the policy that any non-finite coordinate pair becomes a paired `NaN` gap.

The renderer gate must use hand-built IR with no open figures, repeat rendering
byte-for-byte, reject an `Inf`-bearing IR, and replay
`test/fixtures/ir/line-v1.json` to identical TeX. Static inspection must confirm
that `src/+m2t2/+render` contains no graphics-handle access or `get` call.

Export all ten figures with legacy `matlab2tikz` and the current `m2t.export`
workflow. Retain the
semantic signature table, compile all 20 standalone documents with LuaLaTeX,
rasterize each PDF pair, and retain the informational pixel metrics and visual
review. Repeat the 100/10,000/100,000 point benchmark without data reduction,
recording reader, renderer, total export, TeX bytes, and LuaLaTeX time.

The M2 prototype remains **MATLAB VALIDATION REQUIRED** until this matrix passes
on every intended supported release. Octave success is evidence for the design,
not a substitute for MATLAB Handle Graphics validation.

## M2.1 schema and axes additions

On every selected MATLAB release, verify the version-2 reader using concrete IR
assertions for manual X/Y ticks and labels, reversed X/Y direction, box on/off,
plain/TeX/LaTeX label interpreters, legend on/off, legend entry order and basic
location, constant-style scatter, symmetric/asymmetric Y errorbar, line+scatter,
and line+errorbar axes. Record the public MATLAB properties actually used for
`Scatter` and `ErrorBar`; compare `YNegativeDelta`, `YPositiveDelta`,
`XNegativeDelta`, and `XPositiveDelta` with Octave's reader branch.

Exercise diagnostics for per-point scatter sizes/colors, filled scatter, complex
legend layout, and unsupported objects. Confirm `M2T2:E007:UnsupportedProperty`
includes type, path, property, and value without losing data silently. Validate
HG2 legend object discovery and the association of legend entries with stable
series IDs, especially when series visibility/order differs.

Replay the committed version-1 JSON fixture through the v1-to-v2 migration and
roundtrip a heterogeneous version-2 JSON document. Renderer tests remain
figure-free and must cover manual ticks, reverse directions, box, text
interpreters, legend order, scatter, asymmetric errorbar, and mixed series.
Compile and visually review the legacy/M2.1 fixture pairs and compare the ten M2
line rasters before/after the axes changes.

All reader assumptions above are **MATLAB VALIDATION REQUIRED**. M2.1 may not be
used to claim MATLAB support until the intended release matrix passes without an
unclassified property or object-model difference.

## M2.2 layout and multiple-axes additions

On every selected MATLAB release, execute the M2.2 reader fixtures for two
independent axes, `subplot(2,1,...)`, `subplot(1,2,...)`, `subplot(2,2,...)`,
manual `Position`, unequal widths/heights, overlapping axes, mixed scales, and
mixed series across axes. Assert normalized plotting rectangles, unique axes IDs,
back-to-front axes order, inferred logical cells, overlay references, and strict
per-axes ownership of series, ticks, labels, and legends.

Record and compare `Units`, `Position`, `OuterPosition`, `TightInset`, and
`ActivePositionProperty` or `PositionConstraint`. Confirm that temporarily
reading `Position` in normalized units restores the original units without a
layout mutation, and that print-oriented `PaperUnits`/`PaperPosition` produces a
stable point size. M2.2 serializes the plotting rectangle, not decorated bounds;
validate this interpretation against HG2 resizing, labels, outside legends, and
manual axes.

Verify HG2 figure child order with overlapping axes and confirm that IR array
order is the intended back-to-front render order. Create independent legends on
axes A and B with different locations and reordered/hidden plot children. Record
the public MATLAB legend-to-axes association used by the reader. A layout-wide or
otherwise unowned/shared legend must fail with
`M2T2:E010:UnsupportedSharedLegend`, never attach to an arbitrary axes.

Replay pre-M2.2 version-1 and version-2 JSON without geometry fields and confirm
the auto-size/full-placement compatibility default. Roundtrip a version-2 grid,
manual placement, and overlay document. Compile/rasterize every Legacy/M2.2 pair
and retain PDF axes bounding boxes, relative centers, widths, heights, pixel
metrics, and visual review.

Future MATLAB-only gates, not M2.2 implementation commitments, are
`tiledlayout`, `nexttile`, spanning tiles, shared labels, shared legends,
`yyaxis`, and layout-owned colorbars. Classify their public HG2 objects and
relationships before extending the IR.

All MATLAB geometry, HG2 ordering, and legend-association assumptions are
**MATLAB VALIDATION REQUIRED**. Layout prototyping may continue, but public
MATLAB compatibility remains blocked until this matrix passes.

## M2.3 colorbar and figure-element additions

On every selected MATLAB release, run C1-C10 and record the public behavior of
`ColorBar.Axes`, `ColorBar.Position`, `ColorBar.Location`,
`ColorBar.Orientation`, `ColorBar.Direction`, `ColorBar.Limits`,
`ColorBar.Ticks`, `ColorBar.TickLabels`, and `ColorBar.Label`. Verify that manual
`Position` is read in normalized units without mutation and remains authoritative
for east/west/north/south-outside and manual colorbars. Compare `Axes.CLim`,
`Axes.ColorScale`, and axes/figure colormap ownership for `imagesc`, surface, and
multiple-axes figures. Confirm whether automatic ColorBar limits/ticks are direct
data values or normalized display coordinates in each target release.

Exercise one axes plus colorbar, subplot plus one owned colorbar, two axes with
independent colorbars, overlapping axes with a colorbar, and any supported shared
colorbar. Retain owner IDs, associated axes IDs, normalized axes/colorbar
rectangles, relative gaps, orientation, limits, ticks, labels, compiled PDFs, and
raster review. In particular, confirm that adding a colorbar does not collapse a
subplot, cover its plotting rectangle, or escape the physical figure canvas.

Classify `tiledlayout`-owned colorbars without implementing the tiled-layout
reader: record layout owner, affected axes, `Layout`, tile behavior, and public
ownership references. Do the same for combined/shared legends and shared
`xlabel`, `ylabel`, and `title`. A shared legend must preserve `{axesId,
seriesId}` references across axes; shared labels must map to figure/layout owners
without dummy axes. Until a public runtime mapping is confirmed, construct these
nodes only in figure-free IR/renderer tests.

Create a real `yyaxis` figure and require the explicit unsupported diagnostic;
it must not be normalized as ordinary M2.2 overlay axes. Heatmap rendering,
`nexttile` parsing, `TileIndex`, `TileSpan`, `TileSpacing`, and `Padding` remain
outside M2.3.

All MATLAB `ColorBar` ownership/layout semantics, shared-element runtime
discovery, and HG2 property assumptions are **MATLAB VALIDATION REQUIRED**.
