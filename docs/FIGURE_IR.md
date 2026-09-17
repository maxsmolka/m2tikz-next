# FigureIR compatibility contract

FigureIR is the handle-free scientific representation between readers and
renderers. Its current root is `kind='m2t2.figure', version=2`; this `version`
is not the independent figure-set manifest `schemaVersion=1`. The public API
remains [m2t.export / m2t.exportSet](API.md). `m2t2.*`, constructors and JSON
helpers remain internal/experimental interfaces, but stored supported schema
semantics follow this explicit M7.1 compatibility policy.

## Compatibility direction and version changes

Same-version evolution is backward-readable: an older supported document
retains its scientific meaning in the newer implementation under documented
defaults. Optional additive fields and new discriminated node kinds can remain
v2. This does **not** promise that an old implementation understands new kinds
or new required semantics. Unknown kinds fail, rather than being omitted.

A schema bump is required for incompatible reinterpretation, numeric/type
changes, removal/renaming of required semantics, changed scientific defaults,
or ownership/order changes that cannot be safely defaulted. Bumps require a
documented deterministic migration or an explicit unsupported-version failure.
Correctness fixes rejecting malformed/ambiguous input outside the supported
schema are not a license to reinterpret previously valid data. Tests and an
ADR must explain compatibility decisions; see
[ADR-0025](adr/ADR-0025-figureir-compatibility-contract.md).

## Data model and semantic order

| Node / area | Scientific contract |
| --- | --- |
| Figure | Ordered `axes`, `elements`, `annotations`; optional physical `size` in TeX points and explicit `layout`. Empty size is the historical renderer-sizing mode, not a guessed physical measurement. |
| Axes | Unique `id`, 2-D/3-D `kind` and `dimensionality`; limits/scales/directions/ticks, labels/title, placement, overlay relation, color mapping, legend and ordered series. `overlayOf` references an earlier overlapping axes. |
| Layout | Freeform or explicit grid; ordered cells identify axes with one-based row/column/span. `layout.tiled` means fixed native layout intent, indexing/spacing/padding and resolved-runtime geometry; its absence means historical grid/freeform behavior, not guessed tiledlayout. |
| Text / ticks | TextIR has value and plain/tex/latex interpreter. Ticks distinguish auto/manual values and ordered labels. Literal strings in historical v2 text slots normalize to plain TextIR. |
| Line / errorbar | Paired coordinate vectors, paired NaN gaps, styling and all directional uncertainty vectors. No point reduction; no inference of missing coordinate/error vectors. |
| Scatter / scatter3 | Explicit constant/per-point marker diameter in points (reader converts source area), constant RGB / N-by-3 RGB / scalar color data, independent edge/face modes. Point order and all aligned arrays stay paired. Scatter3 also requires Z and explicit scene order. |
| Image | X/Y centers and rows(Y)-by-columns(X) scalar data or rows-by-columns-by-3 RGB in [0,1]. Scalar mapping and direct index base are explicit. Opaque/constant/per-pixel alpha is image-owned. No inferred alpha/color conversion. |
| Color mapping / colorbar | Axes-owned limits, colormap and linear scalar mapping; colorbar owner/associated axes/display must agree. RGB has no invented scalar mapping. |
| Dual Y | `axes.dualY` adds left color and full right ruler state; every series must say `yAxis='left'` or `'right'`. Missing side is an error, not left-side fallback. Absent dualY means historical single Y. |
| Scientific 3-D | Explicit orthographic view/aspect, data coordinates and supported scene order; Surface, Line3, Patch3 and bounded Scatter3/wire mesh. No camera/occlusion inference. See SCIENTIFIC_3D.md for acceptance limits. |
| Bars / boxplots | Explicit axes ownership, group membership/category/value or resolved statistics/outliers. Optional BarIR `xBounds` retains runtime-resolved rectangle bounds. Absence retains the historical formula, not inferred patch geometry. |
| Elements / annotations | Explicit figure/layout/axes owners and references. Axes-data text and figure-normalized arrows retain their coordinate spaces; no ownership guessing. |

Arrays are ordered semantic sequences, not sets. Do not sort axes, series,
legend entries, cells, annotations, samples or pixels. JSON object-key order
is not semantic. A renderer may perform only the documented explicit scatter3
depth ordering, preserving equal-depth ties and every aligned point role.

Planner choices/reasons, render plans/assets, profile application metadata,
diagnostics, workflow timings and manifest status are **not FigureIR fields
required for replay**. They are produced from IR and explicit configuration.
Do not persist runtime handles, temporary paths or incidental machine metadata
as semantic IR. User-provided text/opaque metadata is caller content.

## Missing fields and normalization

`fromJson` supports versions 1 and 2 only and returns validated current v2.
Current in-memory `validate` requires normalized fields; it does not fill them.
The loader fills only documented constructor defaults for older JSON.

Required v2 input: root kind/version/axes; each axes kind/id/xlim/ylim/xscale/
yscale/series; each series kind and its scientific payload. Payload means X/Y
(plus Z for 3-D points), all four errorbar uncertainty vectors, image X/Y/CData/
mapping, surface X/Y/Z/C, patch vertices, bar owner/categories/values/group
identity/index/count, or boxplot owner/positions/statistics/outliers. Figure
elements and annotations require an owner with explicit kind and ID. Colorbars
require associated axes/limits, shared legends entries, shared labels role/text,
text annotations position/text/coordinate space, and arrows kind/endpoints/
coordinate space. A missing payload is not an empty
series. Explicit empty line coordinate vectors remain valid empty data.

Known historical defaults include:

- missing figure size/layout/elements/annotations: empty size, freeform layout,
  empty ordered collections; missing placement: full normalized rectangle;
- absent 3-D additions on old 2-D axes: 2-D, orthographic/top-view defaults;
  newly claimed 3-D scene/camera ownership cannot be inferred;
- missing pre-M6.1 scatter additions: constant size/color, empty point colors,
  constant edge using legacy color, no face. Explicit provided edge/face colors
  are retained, not overwritten by a missing mode;
- missing pre-M6.2 image additions: scalar color, one-based direct indices,
  opaque alpha one; RGB/alpha cannot masquerade as these defaults;
- absent dualY/tiled/background/xBounds: historical single ruler/non-native-grid/
  unfilled background/bar formula respectively. Native readers now explicitly
  record supported white/none backgrounds and resolved bounds where needed;
- absent/empty series ID: the existing legacy v2 normalization assigns
  `<axesId>-series-<one-based-index>` deterministically. This narrow historical
  exception is not permission to invent axes IDs or semantic owners.

Style/text/tick/color-map defaults are the named `make*` constructors and are
locked by the committed normalized golden files. Missing semantic fields,
malformed matrices, inconsistent modes or ambiguous references fail. A matrix
cannot be flattened into an allegedly valid coordinate vector. Known vector
orientation normalizes to rows; JSON struct/cell collections normalize to
ordered row-cell arrays. Numeric MATLAB storage class is not scientific
meaning; normalized values/shapes/modes are.

Unknown v2 **fields** are preserved as opaque JSON-safe extension data and are
not interpreted by the renderer. Keys must be portable ASCII identifiers
starting with a letter, followed by letters/digits/underscores, at most 63
characters; unsafe names fail rather than be silently renamed. The known
ArrowIR `end` field is preserved, including on Octave, whose default JSON
decoder otherwise renames it. Fields must be optional/nonsemantic: a producer
must never rely on an unknown field to alter scientific meaning in an older
consumer. There is no forward-compatibility guarantee for such semantics.
Unknown kinds/enums and unsupported required content fail explicitly. Metadata
field retention is tested; arbitrary executable/native objects are not JSON.

## Migration and failure boundary

Version 1 migration is restricted to the historical figure/axes2d/line schema.
It preserves coordinates/styles, wraps text as plain, assigns stable IDs,
sets visible/normal directions/automatic ticks/boxed axes, and builds ordered
legend entries from nonempty display names. The original committed
`test/fixtures/ir/line-v1.json` remains unchanged. Unsupported v1 kinds or extra
semantic fields are rejected, never silently treated as lines. No source JSON
is rewritten automatically. No versions other than 1/2 are migrated.

Missing/malformed/unsupported version and unsupported node kinds use
`M2T2:E008:UnsupportedIRVersion`; malformed JSON/current semantic data uses
`M2T2:E003:InvalidIR` or the existing precise reference/ownership diagnostic.
Unsupported future version 3/99 fails before rendering. Prose is not a stable
contract. Correctly versioned data must still satisfy supported capabilities.

## JSON and canonical-byte boundary

Use the internal `m2t2.ir.toJson(ir)` / `m2t2.ir.fromJson(text)` pair for
reproducible internal persistence. This adds no public export option and does
not alter public TeX, manifest serialization or its 15-digit TeX precision.
`toJson` validates first, normalizes through the v2 loader, sorts object keys
lexically, retains array order, uses compact JSON without a trailing newline,
canonical zero and 17-significant-digit finite double numbers with decimal
point. Matrix dimensions are explicitly nested in JSON, including singleton
dimensions. Integers beyond exact double range fail rather than lose bits.

Numeric-array `null` represents supported NaN gaps. A scalar NaN is `[null]`,
not bare `null`; empty numeric data is `[]`. Bare object-valued null is rejected
as ambiguous. Previously raw `jsonencode`/`jsondecode` converted a single NaN
coordinate to an empty vector. Octave's observed raw encoder also emitted wrong
values for realmin/realmax; the explicit numeric writer avoids that path.
Raw runtime JSON encoding is therefore not the archival codec contract.
Existing unambiguous supported JSON remains readable. A bare-null file must be
recovered from source: explicitly choose `[]` for empty data or `[null]` for a
single NaN. The loader must not guess which was meant.

Semantic roundtrip equality means normalized numeric values (including paired
NaNs), matrix shapes, text, ownership and ordered collections; empty-array
storage shape, numeric class and struct insertion order are not promises.
Binary-double edge tests include realmin, realmax and 1+eps. This is distinct
from TeX/PNG precision in [DETERMINISM.md](DETERMINISM.md).

Canonical byte identity is promised for the same codec implementation and
normalized data, including input object-key permutations and repeated reloads.
Nine ASCII synthetic goldens have identical bytes in the tested MATLAB/Octave
runtimes. That observation is not a universal Unicode/JSON-library/version
byte promise. Adding future optional defaults can change normalized JSON bytes
without changing schema meaning; review/update goldens deliberately, never
blindly. Scientific TeX and decoded PNG equivalence are independently tested.

M7.3 additionally locks a shared Unicode-containing JSON/TeX fixture in the
observed Windows MATLAB and Linux Octave environments; see the
[environment contract](ENVIRONMENT_CONTRACT.md). This expands concrete evidence,
not the universal byte promise or the FigureIR schema version.

## Committed evidence

`test/fixtures/ir/compatibility` contains nine input/normalized-canonical pairs:
pre-M6.1 and rich scatter, pre-M6.2 scalar image and RGB/per-pixel alpha, fixed
tiled layout, dual Y, scientific 3-D, optional bar/background additions, and
NaN line gaps. `runM71FigureIrContractTests` adds v1 migration, version failure,
missing/unknown fields, explicit owners, numeric/null/singleton edges and order.
`runM71FigureIrTexTests` compiles all nine classes with independent image assets.
These are portable stored-IR checks, not additional native graphics coverage.
