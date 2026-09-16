# Unsupported content and partial-output policy

The modern workflow analyzes the complete encountered figure before planning
or creating export products. A supported family is not permission to discard
unknown children or unrepresented scientific properties. Runtime support is
bounded by [SUPPORT.md](SUPPORT.md), not by a claim to reproduce every property
of every MATLAB/Octave release.

## Classification and traversal

| Encountered content | Classification and treatment |
| --- | --- |
| Figure/axes children, including `HandleVisibility='off'` | Traverse with `allchild`; hidden handles do not imply nonsemantic content. |
| Known invisible series | Supported: retain visibility in IR; do not draw them. A hidden figure remains exportable without showing it. |
| Unknown classes, groups, panels, nested containers or annotations | Unsupported with a structured diagnostic, even when hidden. No recursive flattening guess. |
| Line/scatter/errorbar/image/surface/patch families | Supported only through their explicit semantic reader and property guards; unknown primitive children and active brushing are rejected. |
| UI menus, toolbars, context menus | Ignored: these are editor/application controls, not figure plot content. Callbacks are not executed to interpret them. |
| Axes label/title handles | Read as semantic properties, not duplicated as free text. Invisible label text stays absent. |
| Octave legend/colorbar watcher text | Ignored only when empty, invisible, handle-hidden, axes-owned and linked by the expected runtime ownership/callback references. A matching tag alone is insufficient. |
| Recognized compound-surface empty text | Ignored only with empty content and no represented background/edge; nonempty compound text is rejected, not dropped. |
| Proven empty runtime bookkeeping groups | Ignored only by the existing empty-child/hidden-handle/empty-userdata/owner/context signature; arbitrary empty groups remain unsupported. |
| Fixed tiled layout, shared labels and decorations | Explicit cells/spans/ownership; unknown children and unsupported outer/nested/flow variants fail. |
| Dual Y axes | Every child must resolve to exactly one ruler side, including hidden handles. No range/color/order-based ownership inference. |
| Legend entries | Resolve actual object links and order; subsets/reordering remain attached to the selected series. A single linked Box child may represent its uniquely recognized boxplot compound. Unknown/duplicate compound links fail. |
| Colorbars | Require explicit axes ownership, linear mapping, supported orientation and matching display limits. Read actual runtime ticks, direction and label; hidden/manual-orientation variants fail. |
| Bars | Known semantic object only. Octave compounds may contain the one patch and its linked baseline, not arbitrary extra children. Patch geometry/style must match the normalized grouped bars. |
| Boxplots | Existing narrow resolved-statistics signature plus complete child roles. Child coordinates/visibility must agree with those statistics; edited medians/outliers cannot be replaced by stale stored values. |
| Octave errorbars | Proven creator and exactly two line children; ordinary X/Y/XY errors only. Center/error geometry, visibility and colors must agree with semantic properties. Error-box formats and extra/tampered children fail. |

Recognition uses multiple positive capabilities/ownership facts, not a tag
alone. Runtime-private semantic signatures remain tested implementation details,
not a promise of compatibility with untested future runtimes.
Octave gnuplot scatter compounds must have the exact observed patch partition,
coordinates, visibility and marker/color state. Extra or edited patches fail;
the creator marker alone is insufficient. Native scatter primitives retain
their own property/child guards.
Axes-backed Octave legends/colorbars reject unlinked/unknown children and
modified colorbar image data instead of discarding their visible additions.

## Property boundaries

Central reader guards reject currently unrepresented states such as hidden
axes, alternate single-axis sides/origins, rotated ticks, minor grids, axes
subtitles, nonnumeric rulers, selected marker indices, independently colored
or filled line markers, nondefault error caps, active brushing, primitive
clipping changes, and decorated/clipped free text. Nonwhite axes backgrounds
are rejected rather than potentially hiding white scientific marks on the
export's white canvas; transparent axes require a white figure background.
Supported white/transparent axes explicitly carry optional AxesIR `background`
(`white` or `none`). The renderer preserves opaque white overlays and keeps
dual-Y helper layers transparent. Missing fields in older portable IR retain
the historical unfilled background; no old semantics are guessed.
Callers using dark-theme defaults must explicitly construct a supported source
style; the reader never changes background or data colors to force acceptance.
Existing family-specific
guards still handle alpha, data shape, color mapping, coordinate spaces,
lighting, bars, boxplots, tiled layout and dual-Y restrictions.

All native 3-D families now use the same automatic orthographic camera and
scene-order checks, including older surface/Line3 compounds. Multiple objects
with unresolved depth sorting fail; explicit source `SortMethod='childorder'`
is the supported ordered-painting contract. The exporter does not set it for
the caller. This deliberately closes previously unguarded behavior; it is not
a new scene-wide occlusion implementation. Standalone supported surfaces and
Line3 remain supported.

Scalar vector images with fewer than two rows or columns fail before file
creation because the matrix-plot backend cannot represent that shape. Explicit
hybrid retains the original one-row/one-column pixel dimensions. `auto` is not
silently changed to bypass this failure.

## Explicit presentation limitations

Export is a semantic scientific renderer, not a screenshot or complete desktop
appearance clone. Automatic ticks, text/font layout, outer canvas and
default axes/legend cosmetics follow the documented export/profile model;
`best` legend placement retains its documented fixed-location approximation.
Octave error-cap lengths are normalized to physical renderer cap styling.
Octave gnuplot internally groups large scatters by rounded marker size and can
display only the first RGB color of a large patch. The reader verifies that
runtime representation but exports authoritative parent sizes/per-point RGB
without reproducing those display reductions. Octave bar rectangles retain
their validated native X boundaries in optional BarIR `xBounds`; older IR
without that field retains its established grouped-geometry default.
Bar baseline values are data semantics; runtime baseline-line cosmetics are
not a separate exported primitive. These are explicit presentation limitations,
not permission to lose coordinates, uncertainties, labels, colors, ownership,
visible objects, or meaningful custom child geometry. Non-square 3-D viewport
sizing is not claimed pixel-identical to native MATLAB.

Inactive properties (for example AlphaData when opaque alpha is selected),
data-source expressions already resolved into arrays, interaction callbacks,
selection handles and application metadata are nonsemantic for the static
export. No callback/data expression is evaluated as an export fallback.

## Failure and deterministic diagnostics

The first failure in deterministic figure/axes/child traversal ends analysis;
the API does not promise an exhaustive list of every defect in one call.
Stable codes identify the unsupported family/property/ownership boundary;
message text adds context but is not a frozen interface. Existing codes are
reused rather than creating parallel aliases; see
[DIAGNOSTICS.md](design/DIAGNOSTICS.md).

Analysis failures return `success=false`, normally `status='unsupported'` for
registered capability diagnostics. Invalid IR is an explicit invalid-analysis
failure. Neither path writes TeX/PDF/assets, deletes prior products under
`Overwrite=true`, mutates source data, nor delegates to legacy `matlab2tikz`.
Representation failures discovered during render planning also occur before
product preparation. Compiler failures remain failures, not reduced retries.
Successful-looking material partial output is never the recovery policy.

The M6.7 matrix checks repeated classification/codes, unchanged source state,
existing-product sentinels, unknown and hidden children, ownership and modified
compound data. Native MATLAB and Octave counts are reported separately; the
nine real compiler workflows prove supported neighbors still export successfully.
