# m2tikz-next — M2 Line IR Prototype Report

## Executive Summary

M2 demonstrates the requested vertical slice without changing the public legacy
entry point:

```text
Figure -> runtime reader -> version-1 normalized IR -> handle-free renderer
       -> standalone PGFPlots -> LuaLaTeX -> PDF
```

All ten line fixtures pass the reader and M2 semantic checks on GNU Octave
11.3.0. The independent hand-built-IR renderer test, invalid-IR test, and JSON
replay pass. All 10 legacy and 10 M2 standalone documents compile with LuaLaTeX.
Repeated rendering of identical IR is byte-identical. No data reduction is used.

The architecture is viable, but the prototype is not production-complete. The
current IR lacks tick policy, axis direction/box, layout, legend placement,
interpreters, and secondary-axis concepts. The M2 serializer is also slower than
legacy at 100,000 points, produces about 5% more TeX, and its 100,000-point PDF
compile is materially slower in this run. MATLAB remains unavailable. The final
decision is therefore **CONDITIONAL GO FOR M2.1**.

## Architecture

The prototype is isolated in `src/+m2t2`:

- `m2t2.export` is the experimental three-argument API.
- `+reader` is the only handle-aware layer.
- `+ir` defines constructors, JSON normalization, and validation.
- `+render` consumes only IR and contains no `get` call.
- `+util` owns canonical text, color, style, marker, escaping, joining, and
  `%.15g` numeric formatting.

The legacy `src/matlab2tikz.m` was not edited and is still the reference path.
M2 neither calls the legacy renderer nor changes public legacy semantics.

## IR Schema

Version 1 is deliberately small:

```text
FigureIR
  kind: "m2t2.figure"
  version: 1
  axes: AxesIR[]

AxesIR
  kind, id
  xlim, ylim
  xscale, yscale
  xlabel, ylabel, title
  xgrid, ygrid
  series: LineSeriesIR[]

LineSeriesIR
  kind: "m2t2.line"
  x, y
  color, width, style
  marker, markerSize
  displayName
```

The validator checks node kinds/version, required fields, compatible x/y sizes,
finite limits, linear/log scales, normalized RGB, known line/marker enums,
non-negative sizes, text types, and cell-array containment. `Inf` in hand-built
IR is invalid; the reader must normalize it before validation.

## Figure Reader

The reader uses standard Handle Graphics properties and retains ordered axes and
line series. It ignores only runtime UI chrome (`uimenu`, `uitoolbar`, and
`uicontextmenu`), not graphical content. Any non-line axes child or other
graphical figure child fails the entire export with:

```text
identifier: M2T2:E001:UnsupportedObject
message:    M2T2-E001 UnsupportedObject: type=<type> path=<path>
```

The scatter regression confirms both object type and structural path. Runtime
colors, line styles, and markers are canonicalized here. Any point for which x or
y is `NaN`, `+Inf`, or `-Inf` becomes a paired `(NaN, NaN)` gap. This is the
explicit M2 non-finite policy; the renderer never needs runtime-specific rules.

`DisplayName` is captured and currently emitted as a legend entry by M2. The
legacy comparison creates a legend for that fixture because legacy does not emit
`DisplayName` metadata by itself.

All reader behavior is **MATLAB VALIDATION REQUIRED**. In particular, HG2 object
arrays, label-child identity, default UI children, scatter type names, line color
resolution, and empty-line creation must be checked in MATLAB.

## PGFPlots Renderer

The renderer validates its input and emits standalone or embeddable PGFPlots.
It writes explicit ranges, linear/log modes, labels/title, independent major-grid
flags, inline coordinates, normalized colors/styles/markers, display-name legend
entries, and `unbounded coords=jump`.

Numbers use `%.15g`, negative zero is canonicalized, and a decimal comma is
defensively replaced. TeX backslashes are built from character code 92 because
Octave interprets backslash escapes in character literals differently from
MATLAB. This compatibility detail remains below the IR boundary. A direct repeat
of each fixture and the JSON replay produce identical bytes.

## Tests

The focused test inventory is:

| Layer | Cases | Result |
|---|---:|---:|
| Reader fixtures | 10 | 10 PASS |
| Unsupported reader object | 1 | 1 PASS |
| Hand-built IR renderer | 1 | 1 PASS |
| JSON replay | 1 | 1 PASS |
| Invalid `Inf` IR rejection | 1 | 1 PASS |
| Unsupported multi-axes layout | 1 | 1 PASS |
| Legacy standalone LuaLaTeX | 10 | 10 PASS |
| M2 standalone LuaLaTeX | 10 | 10 PASS |

The ten fixtures are minimal, multiple lines, styled line, labels/title/grid,
display names, log-x, log-y, NaN gap, Inf gap, and an empty line. Reader and
renderer tests are separate functions; the renderer tests open no figure.

The post-M2 legacy regression produced the same established baseline:

- M1A focused regressions: 3/3 PASS;
- M1B 3-D/camera regressions: 6/6 PASS;
- ACID: 105 discovered, 0 Golden passes, 87 expected Golden mismatches, and 18
  explicit skips; exit 61 remains expected because no Octave 11.3 Golden table
  has been approved;
- audit harness: 17 `EXPORTED`, one `NOT TESTABLE WITH OCTAVE`, with deterministic
  exports and external/standalone checks intact;
- M1A TeX matrix: 11 PASS and the known raw-Unicode/pdfLaTeX engine limitation;
- independent legacy line smoke: export and LuaLaTeX compilation PASS.

No legacy baseline changed, and `src/matlab2tikz.m` has no M2 diff.

## Serialization

`.audit/m2/ir/line-basic.json` contains the version-1 experiment. JSON arrays are
reshaped to the row-vector IR contract after `jsondecode`, then fully validated.
Rendering decoded JSON is byte-identical to rendering its direct in-memory IR.
JSON is an interchange experiment, not the in-process representation.

## Legacy Comparison

The comparison checks compilation, line-series counts, point counts, emitted
ranges, labels, scale modes, and relevant style/legend tokens. The normal eight
fixtures agree on series and point counts. Two differences are intentional and
recorded rather than hidden:

- `inf_gap`: M2 retains five coordinate records and converts the non-finite point
  to a paired `NaN` gap; legacy emits four data rows. Both compile and render a
  discontinuity, but their data-record semantics differ.
- `empty`: M2 preserves one empty line series; legacy omits the empty series.

TeX is not byte-compared across architectures because their structure is
intentionally different. The full signature table is retained at
`.audit/m2/semantic-results.tsv`.

## Visual Comparison

Every compiled PDF pair is rasterized at 150 dpi. A small Pillow-based tool
centers both grayscale pages on a common white canvas and records normalized mean
absolute error plus the fraction of pixels differing by more than 8/255. It also
writes an amplified difference image. This is explicitly informational, not a
quality gate.

Manual inspection confirms the same lines, gaps, colors, styles, scales, and
labels in representative minimal, styled, and labeled cases. The largest visible
differences are page/axis dimensions and automatically chosen tick density. They
are expected consequences of not carrying pixel geometry or ticks in version 1,
but they are also concrete evidence that the present IR cannot promise visual
identity. Across the ten pairs, normalized MAE ranges from 0.01895 to 0.03726 and
the changed-pixel fraction from 0.02611 to 0.07356. Metrics and images are under `.audit/m2/visual-results.tsv`,
`.audit/m2/raster`, and `.audit/m2/visual-diff`.

## Performance

Single-run Windows/Octave 11.3 measurements, with all points inline and no
reduction:

| Points | Legacy export s | M2 reader s | M2 renderer s | M2 total s | Legacy TeX bytes | M2 TeX bytes | Legacy LuaLaTeX s | M2 LuaLaTeX s |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 100 | 0.173 | 0.012 | 0.012 | 0.025 | 4,368 | 4,425 | 2.717 | 2.727 |
| 10,000 | 0.635 | 0.004 | 0.716 | 0.721 | 373,716 | 393,370 | 3.812 | 4.768 |
| 100,000 | 5.192 | 0.004 | 7.142 | 7.149 | 3,731,212 | 3,928,631 | 13.406 | 26.778 |

Raw export and compile measurements are retained in
`benchmarks/output/m2-line/performance-results.tsv` with the corresponding TeX,
PDF, and logs.

These are single measurements and should not be used as a general speed claim.
At 100,000 points the reader cost is negligible, while per-coordinate rendering
dominates. M2 is about 38% slower than legacy export, its TeX is about 5.3%
larger, and its LuaLaTeX run is about twice as slow in this sample. This does not
invalidate the layering experiment, but it blocks any
performance claim and motivates buffered/vectorized serialization work before a
large-data production path.

## MATLAB Validation Required

MATLAB was not available. `docs/validation/MATLAB_VALIDATION_PLAN.md` now adds
the ten reader fixtures, unsupported-object diagnostic, handle-free renderer,
JSON replay, deterministic output, 20-document compile matrix, raster comparison,
and three-size performance matrix. No MATLAB compatibility statement is made by
the Octave result.

## Architectural Findings

1. **Is the IR clearly simpler than the legacy state?** Yes for the line slice.
   It contains three node kinds and only normalized rendering inputs. This does
   not prove that a future full-coverage IR will remain small.
2. **Can the renderer be tested completely without figure handles?** Yes. The
   hand-built and JSON tests do so, and static inspection finds no `get` in the
   renderer package.
3. **Is the MATLAB/Octave-to-reader separation practical?** Yes on Octave: color,
   style, marker, child ordering, text, empty data, and non-finite behavior were
   contained in the reader/util boundary. MATLAB evidence is still missing.
4. **Is output deterministic?** Yes for tested IR: ten repeated direct renders
   and the JSON replay are byte-identical, using fixed numeric formatting.
5. **Is the new path easier to extend?** Structurally yes: a new series needs a
   reader mapping, schema/validator node, and renderer function without graphics
   calls leaking downstream. Schema evolution and mixed-series axes still need a
   written compatibility policy before M2.1.
6. **What information is missing?** Tick positions/labels, axis direction and
   box, figure/axes layout, legend existence/position/style, text interpreter and
   font semantics, secondary axes, clipping, visibility, per-point styling,
   error data, annotations, and multi-axes placement. Some belong in compatible
   optional fields; others may require IR version 2.
7. **What problems became visible only through the prototype?** Octave's
   backslash-literal behavior affects deterministic TeX construction; JSON loses
   row-vector shape; default figure UI objects must be distinguished from plot
   content; legacy drops empty lines and non-finite records differently; visual
   equivalence depends on tick/layout data omitted from the minimal IR; and a
   clean architecture alone does not make large inline serialization or TeX
   compilation faster.

## Limitations

Only 2-D Cartesian line objects are supported. Multiple axes have IDs and order
but no layout and therefore fail explicitly with `M2T2:E006:UnsupportedLayout`.
There is no
scatter, errorbar, subplot geometry, legend object model, custom ticks, reversed
axis, custom interpreter, or large-data backend. Unsupported graphical objects
fail the entire export. The pixel metric is alignment-sensitive and not a
perceptual metric. Timing data is one local run, not a statistical benchmark.

## Recommendation

**CONDITIONAL GO FOR M2.1**

The reader -> normalized versioned IR -> handle-free renderer boundary is worth
continuing. Before treating scatter/errorbar as a production migration, require:

1. the M2 MATLAB reader matrix on the intended HG2 releases;
2. a schema-evolution decision for optional fields versus version increments;
3. an explicit axes/tick/layout scope so visual differences are intentional;
4. preservation tests for empty and non-finite mixed-series behavior; and
5. profiling/buffered serialization work if 100,000-point performance is a gate.

M2.1 should add scatter/errorbar as new IR node types only after those boundaries
are fixed; it should not route the prototype into the legacy public API.
