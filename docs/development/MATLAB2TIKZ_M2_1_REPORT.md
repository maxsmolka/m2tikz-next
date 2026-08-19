# matlab2tikz 2.0 — M2.1 IR Schema & Axes Foundation

## Executive Summary

M2.1 turns the M2 line prototype into a versioned, heterogeneous plot IR. It adds
explicit axes direction, box, ticks, interpreted text, legend ownership, stable
series identities, scatter, and symmetric/asymmetric errorbar nodes. The runtime
reader remains the only Handle Graphics boundary; the validator and PGFPlots
renderer operate only on normalized data.

The milestone uses IR version 2 because text field types and legend ownership are
breaking changes. Stored M2 version-1 JSON remains replayable through an explicit
v1-to-v2 migration. The committed v1 fixture is unchanged.

On GNU Octave 11.3, all 19 reader tests, 8 figure-free renderer tests, 16 semantic
Legacy/M2.1 fixture comparisons, 20 existing M2 line documents, and 32 new
Legacy/M2.1 documents pass. Visual inspection found and drove a fix for an inline
errorbar-table header that had compiled but omitted its first point. MATLAB is
still unavailable, so runtime-property assumptions remain an explicit gate.

The recommendation is **CONDITIONAL GO FOR M2.2**. The schema is stable enough to
add optional layout metadata and define multiple-axes placement, but M2.2 must not
claim MATLAB support until the validation plan has been executed there.

## Schema Evolution Decision

ADR-0003 defines compatibility in semantic terms:

- a new optional field with a meaning-preserving default, optional metadata, or
  a new discriminated series kind is backward-compatible and keeps the current
  version;
- a removed/renamed field, changed type or meaning, changed rendering default,
  or changed ownership/order is breaking and increments the version;
- an old version is accepted only through a named migration; an unknown version
  fails with `M2T2:E008:UnsupportedIRVersion`.

IR version 1 is therefore not viable as the current schema. Its string-to-TextIR
type changes and implicit-to-explicit legend ownership require version 2. Version
1 remains a supported serialized input, not a second in-memory model.

## Updated IR

```text
FigureIR(version=2)
└─ AxesIR(kind=m2t2.axes2d, id)
   ├─ limits, scales, xdirection, ydirection, box, grids
   ├─ xticks: TickSpec
   ├─ yticks: TickSpec
   ├─ xlabel, ylabel, title: TextIR
   ├─ legend: LegendIR
   └─ series[]
      ├─ LineSeriesIR(kind=m2t2.line)
      ├─ ScatterSeriesIR(kind=m2t2.scatter)
      └─ ErrorbarSeriesIR(kind=m2t2.errorbar)
```

Axes and series IDs are unique within their owners. The validator dispatches by
`kind`, rejects unknown kinds, enforces common identity/text/visibility fields,
and then applies node-specific constraints. A heterogeneous `series` cell array
avoids a large sparse common struct.

## Tick Model

Each axis owns a `TickSpec { mode, values, labels }`:

- `auto`: `values` and `labels` are empty and PGFPlots chooses ticks;
- `manual`: finite values and equally many `TextIR` labels are serialized exactly.

The reader does not freeze MATLAB/Octave automatic ticks into JSON. Manual x/y
fixtures confirm exact values and labels. This cleanly separates author intent
from runtime defaults, although automatic Legacy and PGFPlots layout can still
differ visually.

## Text Model

`TextIR { value, interpreter }` supports `plain`, `tex`, and `latex`. Plain text is
escaped. The small TeX subset supplies an explicit math context when `_`, `^`, or
a command is present; ordinary TeX-interpreted words remain escaped text. LaTeX
strings retain their author-provided delimiters. Fonts deliberately remain out of
M2.1.

Interpreter values are normalized in the reader. More complete MATLAB TeX-subset
parity, Unicode behavior, and MATLAB-specific defaults remain validation work.

## Legend Model

Legend ownership is separate from series naming:

```text
LegendIR
  visible
  mode: automatic | manual
  entries[]: { seriesId, text: TextIR }
  location
```

Each series still carries `displayName`, but the legend independently selects and
orders referenced series. Rendering uses explicit legend images and entries, so
mixed plot kinds and manual order do not depend on plot emission side effects.
Basic on/off and eight cardinal/corner locations are supported. Horizontal and
multi-column legends fail with `M2T2:E007:UnsupportedProperty`.

The current runtime reader covers normal automatic/basic legends. Arbitrary
runtime subsets and reordered legend-object associations need a stronger HG2
association mechanism in a later milestone; the IR itself already represents
them without change.

## Series Model

All series share only:

```text
kind, id, displayName: TextIR, visible
```

The remaining fields live on discriminated nodes. Both validator and renderer
dispatch on `kind`; no runtime or renderer code assumes that all siblings are
lines. Mixed line+scatter and line+errorbar fixtures pass reader, semantic,
serialization, compilation, and visual checks.

## Scatter

The supported slice is a 2-D, unfilled scatter with one color, marker, and marker
size for the whole series. MATLAB/Octave `SizeData` is normalized from area to the
linear marker-size contract. Per-point sizes, per-point/mapped colors, filled
markers, and 3-D data fail explicitly with `M2T2:E007:UnsupportedProperty`; they
are never collapsed silently.

## Errorbar

`ErrorbarSeriesIR` stores x/y base data plus `xNegative`, `xPositive`,
`yNegative`, and `yPositive` extents. M2.1 supports symmetric and asymmetric Y
errors, and the schema/renderer also accept explicit X errors when a runtime
exposes them. Extents must be finite and non-negative at finite points.

The renderer emits a named inline PGFPlots table with explicit minus/plus columns.
The visual QA pass verified that the first and last points, connecting line, and
both asymmetric directions are retained. Errorbar legend imagery currently uses
the base line style rather than a miniature errorbar glyph.

## Non-finite / Empty Semantics

ADR-0004 intentionally chooses scientific traceability over Legacy omission:

- empty series remain present with identity, order, style, and naming;
- any record with non-finite x or y becomes a paired `(NaN, NaN)` gap;
- no `Inf` reaches the renderer;
- error extents at a gap become NaN, while finite records require finite,
  non-negative extents;
- no downsampling, decimation, or record deletion occurs.

This policy is identical for line, scatter, and errorbar. It preserves record
position and prevents a line from bridging an invalid observation. The known
Legacy differences for empty and infinite line data remain deliberate.

## Tests

The M2.1-focused inventory on Octave 11.3 is:

| Layer | Result |
|---|---:|
| Reader field/diagnostic tests | 19/19 PASS |
| Figure-free renderer/JSON tests | 8/8 PASS |
| Legacy/M2.1 semantic fixtures | 16/16 PASS |
| Existing Legacy/M2 line LuaLaTeX matrix | 20/20 PASS |
| New Legacy/M2.1 LuaLaTeX matrix | 32/32 PASS |
| New visual PDF pairs | 16/16 produced and inspected |

The reader fixtures cover manual x/y ticks, reversed x/y axes, box on/off,
plain/TeX/LaTeX text, legend on/off, scatter, symmetric/asymmetric errorbar, and
both requested mixed-series combinations. Unsupported scatter sizes, colors, and
filled markers each assert a precise diagnostic. Renderer tests build IR directly
and never open a figure.

Post-change Legacy regression results are:

- M1A focused runtime regressions: 3/3 PASS;
- M1B 3-D/camera regressions: 6/6 PASS;
- M1A TeX matrix: 11 PASS plus the expected raw-Unicode/pdfLaTeX limitation;
- ACID: 105 discovered, 87 expected Golden mismatches, 18 explicit skips, and
  expected exit 61 because no Octave 11.3 Golden table is approved;
- audit harness: 17 deterministic exports and one Octave-only not-testable case;
- independent Legacy smoke export and LuaLaTeX compilation: PASS.

`src/matlab2tikz.m` has no M2.1 product diff.

## JSON Compatibility

The loader accepts v1 and v2 JSON and always returns validated v2 IR. Migration
defaults preserve the M2 rendering contract: normal directions, automatic ticks,
boxed axes, literal/plain old text, visible series, generated stable IDs, and an
automatic legend for non-empty old display names. The stored
`.audit/m2/ir/line-basic.json` remains version 1 and replays successfully.

Version-2 JSON roundtrip is covered with a heterogeneous line/scatter/errorbar
axes. JSON array shapes are normalized back to row vectors. Unknown versions and
unknown series discriminators fail explicitly.

## Legacy Comparison

Sixteen comparisons verify series count, point count, ranges, ticks, directions,
text, legend entries, scatter markers, error extents, and required TeX semantics.
All 16 pass. TeX is intentionally not byte-compared across the architectures.

The Legacy exporter is still the behavioral reference for supported surface
semantics, while M2.1 intentionally differs for empty/non-finite data and can
differ in page geometry because it does not reproduce the Legacy layout engine.

## Visual Comparison

All PDF pairs are rasterized at 150 dpi, centered on a common white canvas, and
compared using normalized mean absolute error (MAE) and changed-pixel fraction.
The metrics are informational rather than acceptance thresholds.

For the ten original line fixtures, M2-to-M2.1 results are:

| Fixture group | MAE before → after | Changed fraction before → after |
|---|---:|---:|
| 8 unchanged cases | unchanged | unchanged |
| display name | 0.03725650 → 0.03729642 | 0.06144291 → 0.06142797 |
| empty | 0.01894657 → 0.01496787 | 0.02610831 → 0.02201668 |

Explicit ticks and directions do not retroactively change old auto-tick fixtures,
which is intentional. Visual agreement therefore does not broadly improve on the
old line set; it is stable in eight cases, nearly neutral for display-name legend
ownership, and better for empty data. The new fixtures demonstrate that manual
ticks, reverse axes, box, text, legends, scatter, and errorbars are represented
semantically rather than relying on accidental PGFPlots defaults.

## Performance

The M2 profile identified per-coordinate `sprintf` calls and incremental string
construction as the 100,000-point hotspot. M2.1 uses buffered, vectorized
coordinate serialization without changing precision, ordering, or record count.

Single-run Windows/Octave measurements, with inline data and no reduction:

| Points | Legacy export s | M2.1 reader s | M2.1 renderer s | M2.1 total s | Legacy TeX bytes | M2.1 TeX bytes |
|---:|---:|---:|---:|---:|---:|---:|
| 100 | 0.180 | 0.021 | 0.010 | 0.030 | 4,368 | 4,488 |
| 10,000 | 0.603 | 0.006 | 0.037 | 0.043 | 373,716 | 393,433 |
| 100,000 | 4.852 | 0.006 | 0.307 | 0.317 | 3,731,212 | 3,928,694 |

The renderer-only 100,000-point time improves from the M2 baseline of 7.142 s to
0.307 s (about 95.7% lower). File writing is about 0.004 s in the isolated profile;
coordinate formatting remains the dominant renderer work. LuaLaTeX compilation
is still slower for the larger M2.1 inline document (24.0 s versus 12.2 s Legacy),
so this is a serialization improvement, not an end-to-end TeX performance claim.

## MATLAB Validation Required

MATLAB was not available. `docs/validation/MATLAB_VALIDATION_PLAN.md` now lists
manual ticks, directions, box, text interpreters, legend association, scatter,
errorbar public properties, mixed child order, diagnostics, JSON replay, and
handle-free rendering. In particular, the MATLAB `ErrorBar` delta properties,
scatter style properties, Legend/HG2 association behavior, and child ordering are
**MATLAB VALIDATION REQUIRED**.

## Remaining Architecture Gaps

- Multiple axes still fail with `M2T2:E006:UnsupportedLayout`; axes IDs and order
  exist, but position, size, overlay groups, shared axes, and colorbar ownership do
  not.
- Legend reader association is basic; the IR supports arbitrary entry selection
  and order, but all runtime permutations are not yet recovered.
- Text covers semantics, not full MATLAB TeX parsing, font, alignment, rotation,
  or rich annotations.
- Scatter excludes filled and per-point style data.
- Errorbar does not yet promise every MATLAB horizontal/vertical object variant.
- Automatic tick and page geometry remain backend choices and need not match
  Legacy pixels.
- Large inline PGFPlots documents still have a TeX compilation cost.

These gaps can be added as optional v2 fields or new node kinds. None requires a
known rewrite of the v2 series discriminator, tick, text, or legend ownership
model.

## Recommendation

**CONDITIONAL GO FOR M2.2**

Explicit answers to the milestone questions:

1. **Is IR version 1 still viable?** No as the current schema; yes only as a
   migrated stored-input format.
2. **Are optional fields sufficient, or is v2 required?** Version 2 is required
   for changed text types and legend ownership. Future additive layout fields can
   remain v2 when their defaults preserve meaning.
3. **Do different series types work cleanly in one axes?** Yes for tested
   line+scatter and line+errorbar, including JSON and compilation.
4. **Is legend semantics sufficiently separate?** Yes in the IR and renderer;
   runtime recovery of arbitrary subset/reorder associations remains limited.
5. **Are auto and manual ticks cleanly modeled?** Yes. Auto stays symbolic;
   manual values and labels are exact.
6. **Did visual agreement improve?** It remained stable for most old line cases,
   improved for empty data, and is nearly neutral for display-name legends. New
   semantics are visibly correct, but no broad pixel-equivalence claim is made.
7. **Does the renderer remain handle-free?** Yes; static scanning finds no Handle
   Graphics/runtime access in `src/+m2t2/+render`.
8. **Is JSON backward compatibility preserved?** Yes through tested v1 migration
   plus deterministic v2 heterogeneous replay.
9. **Did performance improve?** Yes materially: 7.142 s to 0.307 s for the
   100,000-point renderer in the comparable benchmark.
10. **Is the architecture ready for layout and multiple axes?** Ready to design
    and add them without revising the established series/tick/text contracts, but
    not yet capable of rendering them. MATLAB validation is the remaining release
    condition, hence the conditional recommendation.
