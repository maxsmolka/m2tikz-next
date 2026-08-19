# matlab2tikz 2.0 - M2.3 Colorbar & Figure-Level Elements

## Executive Summary

M2.3 adds a runtime-neutral figure-element layer to FigureIR v2. Colorbars are
explicit nodes rather than fake plot axes, combined legends can reference series
across axes, and shared X/Y/title labels belong to a figure or layout. The
renderer remains handle-free and renders every node from IR alone.

On GNU Octave 11.3, C1-C10 pass 10/10, figure-free IR/renderer tests pass 11/11,
Legacy/M2.3 semantic fixture exports pass 10/10, and 29/29 generated LuaLaTeX
documents compile. PDF inspection finds all tested colorbar rectangles inside
the page and zero plot-rectangle overlap. All prior M2.2, M2.1, M2, M1A, and M1B
regressions retain their earlier results.

The recommendation is **CONDITIONAL GO FOR M3**. The ownership and rendering
foundation is stable enough for a user-oriented Scientific Figure Export
Workflow. MATLAB HG2 ownership/layout behavior is still a release gate, and M2.3
deliberately does not export image/heatmap pixel data.

## Ownership Decision

ADR-0006 defines a stable reference object:

```text
owner = { kind: axes | layout | figure, id: stable-id }
```

Axes IDs are existing IDs; `figure` and `layout` are reserved root IDs. The
validator resolves all owners and cross-node references after axes normalization.
`M2T2:E012:InvalidFigureElementReference` reports dangling references, while
`M2T2:E011:UnsupportedColorbarOwnership` reports inconsistent shared mappings.
No handle, runtime class name, or nested runtime object is serialized.

## Figure-Level Element Model

FigureIR v2 gains an additive `elements[]` array of discriminated nodes:

```text
m2t2.colorbar
m2t2.legend
m2t2.sharedlabel
```

Small type-specific structs avoid a generic record full of empty fields. AxesIR
also gains `colorMapping={limits,scale,colormap}`. Physical figure size is
required whenever figure elements exist because their normalized placement must
resolve to deterministic point geometry.

## Colorbar IR

ColorbarIR contains kind, ID, owner, associated axes IDs, orientation, normalized
placement, logical location, direction, scale, limits, TickSpec, and TextIR
label. Placement is authoritative; east/west/north/south/manual location is
metadata. Axes own scalar-to-color mapping; colorbars display it. A shared
colorbar requires identical limits, scale, and colormap on every associated axes.

## Colorbar Reader

The reader separates tagged Octave colorbar axes before ordinary axes, resolves
their peer through stable runtime relationships, reads actual normalized
position, and creates element IDs in deterministic figure order. Automatic
display limits are taken from owner `CLim`, because Octave 11.3 exposes automatic
Colorbar `Limits`/ticks in normalized 0-to-1 coordinates even for other CLim.

An image child is accepted only for the explicit colorbar semantic slice; its
color mapping is read, but image data is not silently claimed as a supported
series. The same image without a colorbar still fails with the existing E001
unsupported-object diagnostic. Multi-Y-ruler axes are explicitly rejected as
`yyaxis` rather than treated as M2.2 overlays.

## Colorbar Renderer

Colorbars render as dedicated PGFPlots display axes. This strategy preserves
manual placement, multiple independent colorbars, and shared ownership without
binding display geometry to one data axis. It emits the axes-owned colormap,
limits, scale/direction, TickSpec, TextIR label, and physical point rectangle.
West/north tick labels are placed away from the plot.

Attaching `colorbar` directly to an owning plot axis was rejected because it
cannot model one display shared by multiple axes or arbitrary independent
geometry cleanly.

## Shared Legend

The existing axes-owned LegendIR remains unchanged. A figure-level `m2t2.legend`
has owner, placement, location, and entries of `{axesId,seriesId,text}`. Renderer
tests prove that one legend can resolve and render styles from two axes. Octave
does not expose a clean general shared-legend runtime model, so runtime discovery
remains MATLAB VALIDATION REQUIRED rather than being based on an Octave hack.

## Shared Labels

`m2t2.sharedlabel` contains ID, figure/layout owner, role (`xlabel`, `ylabel`, or
`title`), TextIR, and optional placement. Default semantic positions require no
text-geometry engine; an optional normalized rectangle supplies an explicit
center. TikZ nodes render the labels without dummy axes. Runtime discovery is
MATLAB VALIDATION REQUIRED.

## Tests

Before implementation, the requested baseline was rerun: M2.2 completed with
20/20 compiled PDFs and 10/10 geometry pairs; the nested M2.1/M2 run completed
with 32/32 and 20/20 PDFs. The same matrices were rerun after implementation and
retained identical pass counts.

| Layer | Result |
|---|---:|
| C1-C10 runtime reader cases | 10/10 PASS |
| Figure-free IR/renderer/diagnostic cases | 11/11 PASS |
| Legacy/M2.3 semantic fixture exports | 10/10 PASS |
| Legacy colorbar LuaLaTeX documents | 10/10 PASS |
| M2.3 colorbar LuaLaTeX documents | 10/10 PASS |
| Shared-element/JSON LuaLaTeX documents | 9/9 PASS |

The reader cases cover default/east/west/horizontal/manual colorbars, manual
ticks, label, one colorbar on two axes, independent colorbars, and overlapping
axes ownership. Renderer cases cover single/manual/independent/shared colorbars,
shared legend, shared X/Y/title, JSON, E011, and E012. Static scan finds no
graphics access in `src/+m2t2/+render`; the only MATLAB/Octave text match is a
comment explaining TeX semantics.

Post-change regression evidence:

- M2.2: 12/12 reader, 8/8 renderer, 10/10 semantic, 20/20 PDFs;
- M2.1: 19/19 reader, 8/8 renderer, 16/16 semantic, 32/32 PDFs;
- M2 line prototype: 20/20 PDFs;
- M1A runtime 3/3 and M1B 3-D/camera 6/6;
- M1A TeX matrix: 11 PASS plus expected raw-Unicode/pdfLaTeX limitation;
- audit harness: 17 deterministic exports, one Octave-only not-testable case;
- ACID: expected exit 61 for absent approved Octave 11.3 Golden table;
- independent Legacy export/LuaLaTeX smoke: PASS.

The public Legacy exporter source is unchanged. `git diff --check` passes after
normalizing a generated ACID log's trailing space.

## JSON Compatibility

Version 2 is retained. Missing `FigureIR.elements` becomes `[]`; missing
`AxesIR.colorMapping` receives a neutral default. Existing v1, pre-M2.1 v2, M2.1
v2, and M2.2 v2 paths pass through current regression/roundtrip tests. A current
multi-axes document containing colorbar, shared legend, and shared labels
roundtrips to byte-identical deterministic TeX.

## Legacy Comparison

Ten runtime figures are exported through both Legacy and M2.3. Both paths
compile 10/10. Semantic checks compare colorbar existence, owner, associated
axes, limits/scale, orientation, location, ticks/label where applicable, and
positive placement. M2.3 reads CLim as authoritative color scale.

Legacy does not reproduce the manually assigned Colorbar Position in the manual
fixture; M2.3 does. Consequently manual relative PDF geometry differs by 0.387
after normalized-union comparison. This is an intentional fidelity improvement,
not an M2.3 regression.

## Visual Geometry Validation

Seven Legacy/M2.3 PDF pairs were rasterized at 150 dpi and visually inspected.
PDF vector rectangles were independently extracted for plot axes and colorbars.

| Case | Axes | Colorbars | Max relative delta | Colorbar/axes overlap |
|---|---:|---:|---:|---:|
| default | 1 | 1 | 0.033 | 0 |
| westoutside | 1 | 1 | 0.014 | 0 |
| horizontal | 1 | 1 | 0.023 | 0 |
| manual | 1 | 1 | 0.387 | 0 |
| first only | 2 | 1 | 0.040 | 0 |
| separate | 2 | 2 | 0.135 | 0 |
| overlap | 2 | 1 | 0.030 | 0 |

Every extracted rectangle remains inside the physical page. No colorbar covers a
plot rectangle, disappears, or collapses the axes geometry. The separate case's
larger delta reflects two outside colorbars and Legacy's different decorated
spacing. The image fixtures intentionally have blank M2.3 plot interiors because
heatmap/image series are outside scope; colorbar geometry and scale remain valid.

## Performance

Warm-cache interpretation is required because the first LuaLaTeX run spent 15.9
seconds building its font cache. With 1,000 points per axes:

| Case | Axes | Colorbars | Reader s | Renderer s | TeX bytes | LuaLaTeX s |
|---|---:|---:|---:|---:|---:|---:|
| single axes | 1 | 0 | 0.041 | 0.016 | 40,247 | 15.92 cold |
| single + colorbar | 1 | 1 | 0.013 | 0.045 | 52,231 | 2.92 |
| 2 axes + 2 colorbars | 2 | 2 | 0.019 | 0.083 | 104,323 | 3.42 |
| 4 axes + 4 colorbars | 4 | 4 | 0.030 | 0.148 | 208,559 | 4.52 |

TeX size is essentially linear from two to four axes/colorbars, and renderer time
grows sub-doubling from 0.083 to 0.148 seconds. No nonlinear element lookup or
layout behavior is visible at this scale.

## MATLAB Validation Required

MATLAB was unavailable. The validation plan now explicitly covers
`ColorBar.Axes`, Position, Location, Orientation, Direction, Limits, Ticks,
TickLabels, Label, manual placement, subplot geometry, `Axes.CLim`, ColorScale,
colormap ownership, tiled-layout-owned colorbars, shared legend, shared
xlabel/ylabel/title, and explicit `yyaxis` rejection.

All HG2 colorbar ownership/layout semantics and shared-element discovery remain
**MATLAB VALIDATION REQUIRED**. Octave validates the architecture but cannot
establish public MATLAB compatibility.

## Remaining Gaps

- Image/heatmap pixel data is not a SeriesIR and is not rendered.
- Octave automatic Colorbar limits/ticks require owner-CLim normalization.
- Shared colorbar/legend/label runtime discovery is not implemented without a
  trustworthy MATLAB object model.
- `tiledlayout`, `nexttile`, TileSpan/Index/Spacing/Padding remain a separate
  MATLAB-centered milestone.
- `yyaxis`, polar, 3-D, annotations, publication profile, and backend selection
  remain outside M2.3.
- Figure elements require explicit physical size; old auto-sized documents with
  no elements remain unchanged.

## Recommendation

**CONDITIONAL GO FOR M3**

1. **Can IR v2 absorb figure-level elements additively?** Yes; `elements=[]` is
   the compatibility default and no version bump is needed.
2. **Is Colorbar an independent IR entity?** Yes; `m2t2.colorbar` is distinct
   from axes and series.
3. **Is ownership runtime-neutral?** Yes; kind/ID references contain no handles
   or runtime classes.
4. **Do colorbars work with multiple axes?** Yes for independent owned
   colorbars and figure-owned shared IR; MATLAB shared runtime mapping is pending.
5. **Are manual positions reproducible?** Yes; normalized physical placement is
   rendered authoritatively and improves on the tested Legacy result.
6. **Can shared legends reference multiple axes?** Yes through stable axesId and
   seriesId pairs.
7. **Can shared labels avoid axes misuse?** Yes; they are figure/layout nodes
   rendered as TikZ text nodes.
8. **Does the renderer remain handle-free?** Yes; static scan and figure-free
   tests pass.
9. **Is JSON backward-compatible?** Yes for all retained schema generations and
   current deterministic roundtrips.
10. **Is the architecture stable enough for a user-facing export layer?** Yes,
    conditionally on the existing MATLAB validation gate. Further internal
    refactoring is not the highest-value next step.

The next useful milestone should be **M3 - Scientific Figure Export Workflow**,
with clear supported/unsupported UX and MATLAB validation, rather than another
architecture-only refactor.
