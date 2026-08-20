# m2tikz-next — M2.2 Layout & Multiple Axes Foundation

## Executive Summary

M2.2 adds reproducible figure and axes geometry to IR version 2 without changing
the established series, ticks, text, or legend contracts. Runtime figures can now
contain independent, subplot-style, unequal, manually positioned, and overlapping
2-D Cartesian axes. Their normalized plotting rectangles and deterministic
back-to-front order are rendered as multiple PGFPlots `axis` environments in one
`tikzpicture`.

The change is additive under ADR-0003. Old v1 and pre-M2.2 v2 JSON retain the old
backend-auto-sized single-axes behavior through explicit defaults. New runtime
reads carry physical figure size in points, concrete normalized axes placement,
optional logical grid metadata, and optional axes-ID overlay relationships.

On GNU Octave 11.3, 12/12 M2.2 reader tests, 8/8 figure-free renderer tests,
10/10 Legacy/M2.2 semantic comparisons, and 20/20 layout PDFs pass. All 52 prior
M2/M2.1 PDFs also compile through the new geometry path. PDF-extracted relative
axes geometry differs from Legacy by at most about `2.2e-4`, versus mean errors of
about `0.19` to `0.50` for the former collapsed multiple-axes default model.

The recommendation is **CONDITIONAL GO FOR M2.3**. Layout and ownership are stable
enough for new figure-level node kinds, but MATLAB geometry/order/legend evidence
is still unavailable and therefore remains a release gate.

## Layout Decision

ADR-0005 records both logical intent and physical geometry because neither layer
can replace the other:

- `AxesIR.placement` is authoritative render geometry;
- `LayoutIR` is optional grid intent for relationships and future backends;
- freeform/manual/overlay figures remain valid without a grid;
- a future `tiledlayout` reader can populate the same logical model without
  exposing MATLAB classes to the renderer.

Grid rows are one-based and top-to-bottom; columns are left-to-right. Cells can
carry row/column spans, although M2.2 runtime inference emits one-cell spans only.
Inference is conservative: aligned, complete rectangular arrangements become a
grid; arbitrary and overlapping arrangements stay freeform.

## Figure Geometry Model

FigureIR v2 gains:

```text
size: [width height] PostScript points | []
layout: LayoutIR
```

Points are a physical, renderer-neutral unit that maps directly to TeX and can be
converted by other backends. The reader uses print-oriented `PaperPosition`
converted to points rather than persisting operating-system pixels. It restores
the original runtime units after reading.

`size=[]` means backend auto-size. This is the compatibility default for stored
v1 and pre-M2.2 v2 JSON, preserving the earlier renderer behavior. A new runtime
read records an explicit size. M2.2 does not choose publication dimensions such
as `0.9\textwidth`.

## Axes Placement Model

AxesIR gains:

```text
placement: { x, y, width, height }
overlayOf: earlier axes ID | ""
```

Placement values are normalized to FigureIR and describe the runtime axes
`Position` plotting rectangle. They exclude titles, labels, tick-label extents,
legends, and other decorations. Values must be finite; width and height must be
positive; the rectangle must remain inside `[0,1]`. Invalid values fail with
`M2T2:E009:InvalidPlacement`.

`OuterPosition`, `TightInset`, and active-position hints are deliberately not
copied into the semantic core. They describe decorated/runtime layout behavior
and would require a text-metric solver that is outside M2.2.

## Multiple Axes

The former ordinary-multiple-axes E006 restriction is removed. Tested support
includes:

- two independent freeform axes;
- 2-by-1, 1-by-2, and 2-by-2 grids;
- a manually positioned axes;
- aligned axes with unequal widths or heights;
- linear and logarithmic axes in one figure;
- line on one axes and scatter plus errorbar on another.

Each axes retains its own ID, placement, limits, scales, directions, ticks, text,
legend, and heterogeneous series list. Figure axes-array order is the normative
back-to-front render order. Logical layout cells reference axes IDs and do not
duplicate axes content.

## Overlay Axes

Physically overlapping axes are legal. The reader assigns the later/front axes an
`overlayOf` reference to the first earlier overlapping axes and preserves both
independent coordinate systems. The validator requires the referenced axes to
exist earlier in render order and the physical rectangles to overlap.

The renderer emits both environments independently and never attempts `yyaxis`
merging. The tested partial overlap preserves the back axes and draws the front
axes second. Axes background-color/opacity is not yet represented, so exact
opaque-versus-transparent overlay behavior remains a gap.

## Renderer

For explicit-size figures the renderer emits:

```text
one tikzpicture
  fixed point-coordinate canvas
  axis 1: at, anchor=south west, width, height, scale only axis
  axis 2: ...
  ...
```

Normalized rectangles are multiplied by FigureIR point size. The axes are emitted
strictly in array order. `LayoutIR` is not interpreted as a constraint system;
the concrete placement is already renderable. Old auto-size IR omits these
placement options and follows its previous backend default.

Static inspection of `src/+m2t2/+render` finds no `get`, handles, figures,
`subplot`, `tiledlayout`, MATLAB/Octave checks, or other runtime access.

## Reader

The reader separates runtime concerns into small operations:

- figure print size is converted to points;
- axes `Position` is temporarily read in normalized units and original units are
  restored;
- figure children are normalized into stable back-to-front axes order;
- aligned physical rectangles are conservatively classified as grid cells;
- overlaps become ID relationships;
- Octave legends use their peer-axes appdata; a MATLAB `Axes` owner property is
  attempted at the runtime boundary.

Legends remain axes-owned. Two independent axes legends with different locations
and disjoint series IDs pass. An unowned or shared legend in a multiple-axes
figure fails with `M2T2:E010:UnsupportedSharedLegend` instead of being assigned
arbitrarily.

## Tests

M2.2-focused Octave results:

| Layer | Result |
|---|---:|
| Runtime reader geometry/ownership cases | 12/12 PASS |
| Figure-free renderer/JSON cases | 8/8 PASS |
| Legacy/M2.2 semantic geometry pairs | 10/10 PASS |
| Legacy layout LuaLaTeX documents | 10/10 PASS |
| M2.2 layout LuaLaTeX documents | 10/10 PASS |
| Raster/PDF geometry comparisons | 10/10 produced and inspected |

Reader fixtures cover the requested L1-L10 set plus invalid placement and an
unowned/shared-legend diagnostic. Renderer
tests cover horizontal, vertical, 2-by-2, manual, overlay, mixed ownership,
pre-M2.2 JSON defaults, current JSON roundtrip, and E009. No renderer test opens a
figure.

Post-change compatibility results:

- existing M2 Legacy/M2 compile matrix: 20/20 PASS;
- existing M2.1 Legacy/M2.1 compile matrix: 32/32 PASS;
- M2.1 reader: 19/19 PASS;
- M2.1 renderer: 8/8 PASS;
- M2.1 semantic fixtures: 16/16 PASS;
- M1A runtime regressions: 3/3 PASS;
- M1B 3-D/camera regressions: 6/6 PASS;
- M1A TeX matrix: 11 PASS plus the expected raw-Unicode/pdfLaTeX limitation;
- ACID: 105 discovered, 87 expected Golden mismatches, 18 explicit skips, and
  expected exit 61 because no Octave 11.3 Golden table is approved;
- audit harness: 17 deterministic exports and one known Octave-only skip;
- independent Legacy smoke export and LuaLaTeX compilation: PASS.

The public Legacy exporter source remains unchanged.

## JSON Compatibility

Version 2 is retained. The additions have meaning-preserving defaults:

```text
missing FigureIR.size       -> [] (backend auto-size)
missing FigureIR.layout     -> freeform
missing AxesIR.placement    -> full [0,0,1,1]
missing AxesIR.overlayOf    -> no relationship
```

The committed M2 v1 JSON still migrates through the existing v1-to-v2 path. A
hand-built pre-M2.2 v2 document with the new fields removed loads, validates, and
renders without placement options. A current heterogeneous multiple-axes v2
document roundtrips to deterministic TeX.

## Legacy Comparison

Ten direct Legacy/M2.2 comparisons verify axes count/order, point and series
ownership, ranges, log scale, titles, manual tick labels, per-axes legends, and
normalized rectangle geometry. All pass.

Geometry is compared after normalizing the union of plotting rectangles, which
separates relative layout from each exporter’s standalone-page margins. Maximum
semantic geometry errors range from approximately `5.2e-5` to `2.1e-4`; M2.2’s
own IR-to-TeX normalization error is at floating-point noise level.

## Visual Geometry Validation

Every PDF pair is rasterized at 150 dpi. Pixel MAE and changed-pixel fraction are
retained alongside plotting rectangles extracted from the actual PDF vector
content. Representative aggregate ranges are:

| Metric | Observed range |
|---|---:|
| Normalized pixel MAE | 0.0095 to 0.0244 |
| Changed-pixel fraction | 0.0145 to 0.0390 |
| Maximum relative center delta | 0 to 0.000107 |
| Maximum relative width delta | 0 to 0.000214 |
| Maximum relative height delta | 0 to 0.000214 |
| Mean relative geometry delta | 0 to 0.000115 |

For multiple axes, the hypothetical former default in which all axes occupy the
same backend-default rectangle has mean geometry errors from about `0.187` to
`0.502`. M2.2 reduces those to at most about `0.000115`, so layout fidelity is
materially and unambiguously improved.

Visual inspection confirms correct horizontal/vertical/2-by-2 order, unequal
sizes, partial overlay z-order, mixed-series ownership, independent legends, and
unclipped plotting rectangles. Remaining pixel differences come primarily from
absolute standalone page size, tick density, title font weight, and other text
metrics. M2.2 preserves the source 432-by-324-point print canvas in these fixtures;
Legacy produces a more compact standalone page, so pixel identity is not claimed.

## Performance

The 1/2/4-axes benchmark uses 1,000 inline points per axes and no reduction:

| Axes | Total points | Reader s | Renderer s | Total s | TeX bytes | LuaLaTeX s |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1,000 | 0.040 | 0.018 | 0.058 | 40,245 | 3.13 |
| 2 | 2,000 | 0.016 | 0.017 | 0.033 | 80,321 | 3.16 |
| 4 | 4,000 | 0.022 | 0.031 | 0.053 | 160,493 | 3.90 |

The runs are single warm-cache measurements, so small timing inversions are
noise. TeX size is almost exactly linear, the four-axes renderer is roughly twice
the two-axes time, and no quadratic layout structure is visible.

## MATLAB Validation Required

MATLAB was unavailable. The validation plan now explicitly covers subplot 2-by-1,
1-by-2, and 2-by-2; manual and normalized Position; OuterPosition; TightInset;
active-position semantics; HG2 child/z-order; overlaps; per-axes legends; and
print-size conversion. It also records future MATLAB-only gates for
`tiledlayout`, `nexttile`, spans, shared labels/legends, `yyaxis`, and layout-owned
colorbars.

The meanings of HG2 `Position`, `PositionConstraint`, `PaperPosition`, Legend
ownership, and child order are all **MATLAB VALIDATION REQUIRED**. Octave evidence
validates the architecture, not MATLAB compatibility.

## Remaining Gaps

- No decorated-footprint or `TightInset` solver; placement means plot rectangle.
- Logical grid intent is inferred from geometry, not read from `tiledlayout`.
- Shared/figure-wide legends are unsupported and diagnosed with E010.
- Colorbars, shared labels, `yyaxis`, polar, heatmap, 3-D, and annotations remain
  outside the slice.
- Axes background fill/opacity is not represented for exact overlay compositing.
- Placement deliberately rejects rectangles extending outside normalized figure
  bounds.
- Figure point size and Legacy standalone page size need not match because they
  represent different physical-size policies.
- Fonts and text metrics still explain decoration-level pixel differences.

The gaps require additive node kinds, relationships, or metadata; none requires a
known redesign of placement, axes IDs/order, LayoutIR, or axes-owned semantics.

## Recommendation

**CONDITIONAL GO FOR M2.3**

Explicit answers:

1. **Can IR v2 absorb layout additively?** Yes. Defaults preserve old JSON
   meaning, so no version increment is required.
2. **Can multiple axes be represented without schema redesign?** Yes. Axes arrays,
   IDs, normalized placement, logical cells, and order cover all tested cases.
3. **Is physical geometry sufficiently runtime-neutral?** Yes architecturally:
   points plus normalized rectangles contain no runtime classes or pixels.
   MATLAB property semantics still require validation.
4. **Do manual positions work?** Yes; exact normalized reader and renderer tests,
   semantic comparison, PDF geometry extraction, and compilation pass.
5. **Do overlapping axes work?** Yes for independent partial overlap with stable
   back-to-front order and an axes-ID relation. Background opacity remains open.
6. **Do series/legend/tick ownership relationships remain correct?** Yes in all
   mixed and per-axes legend tests; no IDs cross axes boundaries.
7. **Is JSON backward compatibility preserved?** Yes for stored v1, pre-M2.2 v2,
   and current multiple-axes v2 documents.
8. **Is the renderer still fully handle-free?** Yes; static scanning and all
   figure-free renderer tests pass.
9. **Does visual layout fidelity improve?** Yes decisively: multiple-axes mean
   geometry error falls from roughly `0.19–0.50` to at most `0.000115`.
10. **Is the architecture ready for colorbar, shared layout, and later
    `tiledlayout`?** Ready for additive figure-level modeling and ownership links,
    but those features and their MATLAB HG2 evidence are not implemented. This is
    why the recommendation remains conditional.
