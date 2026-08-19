# Support status

This matrix describes evidence for the future first m2tikz-next preview. It is
not a claim of full matlab2tikz replacement coverage.

## Validated

Environment:

- GNU Octave 11.3 on the recorded Windows validation host;
- MATLAB R2026a Update 4 (`26.1.0.3312084`, `win64`) on Windows;
- TeX Live 2026;
- PGFPlots compatibility level 1.18.x;
- LuaLaTeX for all M2 fixture matrices;
- pdfLaTeX for the selected legacy matrix, except the documented raw-Unicode
  engine limitation.

Modern architecture capabilities validated in those environments:

- line, constant-style scatter, and symmetric/asymmetric errorbar series;
- limits, scales, directions, ticks, interpreted text, grids, and per-axes
  legends;
- multiple axes, subplot-style/freeform layouts, manual positions, and overlays;
- axes-owned and multiple independent colorbars;
- shared legends and shared X/Y/title labels from hand-built IR;
- versioned JSON migration, roundtrip, deterministic replay, and handle-free
  PGFPlots rendering.
- scalar images, publication profiles, figure sets, hybrid PNG layers, and
  deterministic automatic backend planning.
- axes-owned 2-D user text in data coordinates and figure-owned normalized
  arrow/double-arrow annotations, with explicit ownership and vector rendering.
- grouped vertical `bar(...)` series with numeric categories, shared finite
  baseline, constant face/edge styles, legends, and single/multiple axes.
- vertical legacy `boxplot(...)` compounds in the validated traditional,
  filled, line-median scope, including resolved quartiles, whiskers, outliers,
  styles, legends, and multiple axes. Creating these source figures requires
  MATLAB's optional Statistics and Machine Learning Toolbox; exporting reads
  public graphics/appdata semantics and does not call toolbox statistics APIs.

M3 development adds a user-facing `m2t.export(...)` workflow. Its complete
line/scatter/errorbar/multiple-axes/colorbar compilation matrix is validated in
Linux CI with GNU Octave 11.3 and LuaLaTeX; the Windows analysis, path, and
structured-failure paths are also exercised locally.

## Experimental

- `m2t.export(...)`, `m2t2.export(...)`, and all pre-1.0 namespaces;
- FigureIR v2 and its JSON representation;
- shared colorbar/legend/label models pending runtime validation;
- publication scripts, benchmark thresholds, and preview packaging.

Experimental means tested in the stated environment but not yet a stable public
compatibility contract.

## Not yet supported or validated

- MATLAB releases other than R2026a Update 4 and MATLAB operating systems other
  than Windows;
- `tiledlayout`/`nexttile`, spans, spacing, and padding;
- `yyaxis`, polar plots, 3-D annotations, arbitrary annotation shapes
  (`textarrow`, rectangle, ellipse, textbox, line, and brace), and migrated 3-D
  rendering;
- per-point scatter size/color, filled scatter, and other diagnosed unsupported
  properties;
- stacked/horizontal bars, histogram objects, categorical arrays, per-bar or
  mapped bar colors/alpha, and arbitrary patch/group compounds;
- horizontal/notched/outline boxplots, `boxchart`, violin/swarm charts,
  arbitrary per-group box styles, and generic statistical compounds;
- a stable installer/package and post-M3 public API stability guarantee.

The inherited `matlab2tikz(...)` legacy API has broader historical behavior, but
its presence does not expand the evidence-based m2tikz-next support claim.

## Planned

- hosted GNU Octave confirmation after the M4.1 branch is reviewed and pushed;
- validation against additional explicitly selected MATLAB releases;
- continued API stabilization;
- later feature milestones chosen from documented unsupported gaps.
