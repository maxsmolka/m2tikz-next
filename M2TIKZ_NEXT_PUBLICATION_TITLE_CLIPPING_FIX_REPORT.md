# Publication title clipping fix

## Reproducer

Baseline public main: `4a26df451edc323867023ca84198c2da39273e5c`.
Before any product change, a deterministic native MATLAB figure used 560 x
420 pixels, normalized axes [0.13, 0.11, 0.775, 0.815], a three-point line and
the short plain title `Acceptance`. Source FigureIR was 420 x 315 TeX points.
Native title extent was recorded in data units, approximately
[0.807989, 1.005350, 0.384025, 0.048638]. These source-font extents are diagnostic
evidence, not used to size text rendered by a different TeX font engine.

| Baseline profile | PDF width | Title character-box top | Result |
| --- | --- | --- | --- |
| Default | 149.01898 mm, including normal standalone border | 7.02553 PDF pt | Full title |
| Publication single-column | 85.00004 mm | -4.94847 PDF pt | Clipped |
| Publication double-column | 170.00008 mm | 8.60353 PDF pt | Full title |

All three exports reported success. Native reference, TeX, transformed IR,
compiled PDFs and rendered previews were retained locally. The failure was
reproduced before implementation; it is not a long-title edge case.

## Root Cause

The reader preserves normalized inner axes geometry and semantic title text.
The publication transform formerly replaced figure size but left untiled axes
rectangles unchanged. At 85 mm the height becomes 181.38632 TeX points, leaving
only 7.5%, or 13.60397 points, above the axes. Publication title font remains
10 pt, and PGFPlots adds its normal title offset/node geometry. Those physical
text dimensions do not shrink with the page. The rendered title crosses the
fixed standalone bounding box; border is intentionally zero for exact widths.
At 170 mm the same relative top space is twice as large and the title fits.

This is the interaction of fixed typography, normalized inner axes geometry,
page scaling and the fixed bounding box. It is not changed scientific data,
the title's string length, axis clipping mode, a custom title y-shift, a shared
title bug or failed compilation. Tiled/dual-Y/broader-3D paths already had
physical gutter policies. Expanding the page would break the width/aspect
contract; shrinking text would break typography.

## Fix

`fitUntiledMargins` extends the handle-free profile layer with the established
physical typography gutter policy. It solves the affine feasibility constraints
for the largest common scale <= 1 and the nearest feasible translation in each
dimension. Existing space counts toward the requirement. Adequate geometry is
unchanged. All untiled axes and colorbars use the same map, preserving manual
arrangements, insets, overlap relationships and ownership. Figure-normalized
arrows follow that map; axes-data annotations and scientific values do not.

No runtime graphics access or PDF/TeX text measurement is added to the product.
No renderer special case, page-padding workaround or arbitrary text shrinking
is used. Title gutters use the existing tiled budget: tick font 8 + title font
10 + established title separation 8 = 26 TeX points. Label/tick/colorbar sides
use their established role budgets. Infeasible or unusably small plot areas
fail with existing `M2T:PROFILE_GEOMETRY_INVALID` before writing products.

## Geometry Contract

Canonical 85/170 mm widths, aspect preservation/clamping, 10/9/8 pt core
typography, line widths, marker roles and data remain unchanged. Untiled exact
normalized rectangles may change only as required by the physical gutter
constraints; their common relative arrangement is preserved. Default profile
is inert. Existing tiled, shared-title, dual-Y and broader-3D paths are unchanged.
Docs and historical ADR supersession notes make this correction explicit.

## Regression Matrix

| Case | Scope |
| --- | --- |
| P01 | Short ordinary title, 85 mm |
| P02 | Same title, 170 mm |
| P03 | Title and X/Y labels |
| P04 | Title and legend |
| P05 | Title, scalar image and labeled colorbar |
| P06 | Two manual axes and titles |
| P07 | Native tiled axes titles / portable explicit tiled IR |
| P08 | Shared tiled title and axes titles |
| P09 | Dual Y title and both labels |
| P10 | Rich scatter with per-point size/RGB |
| P11 | RGB image and per-pixel alpha |
| P12 | Supported scientific 3D |
| P13 | No-title figure |

Every case also has a default-profile control: 26 actual PDFs per observed
runtime. Tests compare non-geometric scientific IR exactly, preserve caller
figures, enforce deterministic repeated TeX, retain sufficiently padded geometry
and reject impossible plotting areas. Existing M3.1 preservation assertions now
check the common affine relationship instead of the incorrect old premise
that every normalized rectangle must remain unchanged.

## MATLAB R2026a Update 5

Native focused P01-P13 and 13 controls passed on Windows, with actual reader,
public export and Linux LuaLaTeX bridge. No other MATLAB release or native
Windows TeX distribution is asserted. Current publication qualification
supersedes Update 4 publication-specific compilation/width evidence; historical
unrelated capabilities retain their actual recorded version.

## Octave / Portable Evidence

GNU Octave 11.3/gnuplot on Linux runs the same matrix. P07/P08/P09 explicitly
use runtime-neutral stored IR, not claimed native tiledlayout/yyaxis parity.
The schematic dual-Y fixture supplies explicit physical size/placement for its
default PDF control; its original schema golden intentionally omitted geometry.

## TeX/PDF Evidence

Real LuaLaTeX/TeX Live 2025 Debian generates local PDFs. The Python geometry
gate reads every PDF text character box, including text outside the visible
page. It requires full short-title presence, all text glyphs inside the page,
title/data-area separation for 2D publication cases and expected page dimensions.
These checks are added to hosted CI with validation-only pdfplumber.
Runtime PDF validation remains existence/size/header, not a generic visual
detector. The bounded synthetic regression reliably detects the known defect.

## Visual Review

The native P01-P13 previews were explicitly inspected. Titles, labels, ticks,
legends, colorbars, alpha, tiled/shared titles and dual-axis ownership remain
visible. No new page padding is introduced. Existing narrow 3D viewport
behavior is unchanged rather than redesigned. Final updated synthetic panel
fixtures use explicit black lines to avoid source-theme ambiguity.

## Publication Width Verification

PDF width checks use an explicit 0.02 mm rounding tolerance. The observed
85.00004 and 170.00008 mm values reflect PDF point rounding, not a changed
canonical contract. Height is also checked against the existing aspect policy.
Typography is not globally rescaled or reduced to fit.

## Full Regression

Full portable acceptance completed successfully: Public Preview and examples,
all extended suites, profiles/sets, rich scatter and image/alpha, S1,
M6.3-M6.8, API/IR compatibility, runtime/environment and P01-P13/default controls.
The final 26 portable PDFs independently passed the glyph/page geometry gate.
Native Update 5 completed M3.1 and calibrated profiles, rich scatter/images,
tiled/dual-Y/3D reader and real workflow suites, unsupported hardening,
determinism, API/IR and runtime/environment regressions. The final native
26-PDF matrix passed independently, with explicit visual review.
All six architecture invariants, docs, citation, confidentiality, actionlint/
YAML and staged whitespace checks passed. Required hosted exact-head jobs
remain a mandatory pre-merge gate; their integration evidence is recorded
separately rather than claiming future CI success in this commit.

## Product Impact

Only profile geometry changes. Scientific values, ownership, legends, color
mapping, image dimensions/alpha, schema versions and default output remain
unchanged. The profile can reject an infeasible plotting rectangle explicitly
instead of emitting an unusably small successful page.

## Public API Impact

No new API, option, alias or dependency for ordinary export. Public APIs remain
`m2t.export` and `m2t.exportSet`; pdfplumber is validation-only. No tag or GitHub
Release is part of this fix.

## Remaining Limitations

Physical gutters are not an arbitrary TeX font-metrics engine. Extremely long
text, dense user-authored manual overlaps and intentional annotations still
need visual review. Do not interpret compiler success as scientific approval.
No broad layout redesign, new graphics family or untested runtime claim.

## Completion Decision

The demonstrated clipping is corrected without changing publication widths,
typography or scientific data. Local regression, physical PDF geometry and
visual gates pass. Ready for the dedicated fix PR; resume external-package
integration only after its required hosted checks, merge and branch cleanup.
