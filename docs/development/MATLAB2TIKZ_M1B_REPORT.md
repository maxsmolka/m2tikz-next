# m2tikz-next – M1B Report

## Executive Summary

M1B converts the Octave 11.3 baseline from unexplained export failures into a
fully classified validation state. The eight `x_viewtransform` failures are
fixed through public camera/axes capabilities, six focused 3D scenarios pass,
and optional ACID fixture dependencies now produce explicit reasoned skips.

The final ACID export baseline is 105 discovered, 0 passed, 87 failed, and 18
skipped. All 87 failures are missing Golden references; there are no remaining
ACID infrastructure, product-export, `x_viewtransform`, or unknown failures.
Every one of the 87 generated TeX/asset sets is nonempty and bytewise
deterministic across two runs. Eighty-one compile with both LuaLaTeX and
pdfLaTeX. Six are rejected because the generated TeX fails both engines.

No `ACID.Octave.11.3.0.md5` was generated. The 81 compiling candidates remain
`MANUAL_REVIEW_REQUIRED` because generic structure/compilation cannot prove
case-specific scientific and visual correctness. This is an intentional
controlled Golden gate, not an incomplete bulk hash update.

**Recommendation: CONDITIONAL GO FOR M2.** Architecture prototyping may proceed
without an IR/renderer change in M1B, but Golden visual approval, six rejected
TeX cases, and the MATLAB validation gate remain conditions for release-quality
compatibility claims.

## Environment

- Repository: `matlab2tikz/matlab2tikz`
- Branch: `master`
- Base/HEAD: `806c97d99f87f8a1e99a7c54e853c25c82aac301`
- OS: Windows 11 (`10.0.26200.8875` reported by the harness)
- GNU Octave: 11.3.0
- TeX Live: 2026
- latexmk: 4.88
- PGFPlots: 1.18.2
- TikZ/PGF: 3.1.12
- MATLAB: unavailable

M1B started from the uncommitted M1A working tree. M0/M1A audit artifacts remain
separate from productive changes. The pre-M1B baseline was ACID 105/0/90/15,
M1A regressions 3/3, audit 17 deterministic exports plus one not testable, and
the M1A compile matrix with 11 engine passes plus one expected limitation.

## Golden Validation

The review set is stored below `.audit/m1b-golden-review/`. It contains one
directory per ACID ID with `source/`, `generated-tex/`, `compiled-pdf/`, and
`metadata/`, plus global logs and the machine-readable `results.tsv`.

Two isolated complete ACID exports were compared. Automated checks record:

- generated TeX existence and nonzero size;
- axis, addplot, and label/title/legend token counts;
- referenced PNG/JPEG/PDF/TSV existence;
- TeX and referenced-asset hashes across the second run;
- NaN/Inf presence requiring case-specific review;
- LuaLaTeX and pdfLaTeX status and actual PDF existence;
- source function, new MD5, review state, and notes.

| Review metric | Count |
|---|---:|
| ACID IDs represented | 105 |
| Successful exports | 87 |
| Explicit skips | 18 |
| Nonempty successful outputs | 87 |
| Deterministic TeX/asset sets | 87 |
| Cases with referenced assets present | 11 |
| Cases without external assets | 76 |
| LuaLaTeX PASS | 81 |
| pdfLaTeX PASS | 81 |
| Compile-rejected exports | 6 |
| `MANUAL_REVIEW_REQUIRED` | 81 |
| `REJECTED` (18 skips + 6 TeX failures) | 24 |
| `AUTO_VALIDATED` | 0 |

Generic checks cannot establish expected series count or scientific equivalence
for every heterogeneous ACID fixture. Consequently no candidate was promoted to
`AUTO_VALIDATED`; the result does not overstate what automation proved.

## ACID Results

Final log: `.audit/runtime-baseline/logs/m1b-acid-final.log`.

| Metric | Count |
|---|---:|
| Discovered/executed | 105 |
| Passed | 0 |
| Failed | 87 |
| Skipped | 18 |
| Expected fixture/dependency limitations | 18 |
| Golden mismatches | 87 |
| Product export failures | 0 |
| Octave compatibility failures | 0 |
| Infrastructure failures | 0 |
| Unknown failures | 0 |

Pass remains zero solely because no approved Octave 11.3 Golden table exists.
The suite now reaches hash comparison for every non-skipped case.

## 3D / x_viewtransform Analysis

The legacy code needs a projected plot-box aspect ratio when either
`DataAspectRatioMode` or `PlotBoxAspectRatioMode` is manual. It formerly
projected the eight normalized cube vertices with MATLAB's `view(axes)` matrix or
Octave's undocumented `x_viewtransform`. Octave 11.3 exposes no transform
property, but provides public camera position/target/up vector, axis limits and
directions, and plot-box aspect ratio.

For an orthographic camera, map data-space camera vectors into physical plot-box
coordinates. Let `s = direction .* plotBoxAspectRatio ./ axisRange`. Then:

```text
forward = normalize((target - position) .* s)
right   = normalize(cross(forward, upVector .* s))
up      = normalize(cross(right, forward))
```

For a normalized plot-box vertex `q`, physical coordinates are
`q .* plotBoxAspectRatio`. The first two projection rows are therefore
`right .* plotBoxAspectRatio` and `up .* plotBoxAspectRatio`. Translation and
depth do not affect the projected bounding dimensions used by the caller.

Older Octave environments that expose `x_viewtransform` retain that path.
Current Octave uses the public derivation. Perspective was already explicitly
unsupported and warned; M1B does not claim to add perspective support.

Manual Octave camera assignment revealed a second cause: Octave leaves `View`
stale. M1B derives PGFPlots azimuth/elevation from the physically scaled
target-to-camera vector when public camera modes are manual. Camera roll remains
outside PGFPlots' two-angle view model.

## Fixes Implemented

- Capability-based orthographic plot-box projection when
  `x_viewtransform` is unavailable.
- Public-camera derivation of PGFPlots view angles for manually positioned
  Octave cameras.
- Binary/wildcard-free copying in the Golden review generator, avoiding the same
  Octave/Windows `copyfile` behavior identified in M1A.
- Structured `skipReason` in test status and visible runner output.
- Session-local loading and function/class capability checks for optional signal
  fixtures; no installation or system-wide mutation.

No version-number switch, broad product `try/catch`, hardcoded projection
matrix, public API change, IR, renderer rewrite, or plot type was introduced.

## Fixture Dependencies

The installed Octave signal package is version 1.4.7 but is not loaded by
default. M1B loads it for the test process when present and then checks the exact
functions/classes required.

- ACID 17: explicit `UNSUPPORTED TEST FIXTURE IN OCTAVE`; nonlinear colorbars
  cannot be created before matlab2tikz runs.
- ACID 47: signal package provides `ellip` and `zplane`; the test now executes
  and exports deterministically.
- ACID 48/49: explicit skip because MATLAB's `dfilt` namespace is unavailable,
  even after the signal package is loaded.
- ACID 62: explicit skip because Octave signal provides `chirp` but not
  `spectrogram`; this capability surfaced only after correct package loading.
- The other 14 skips are existing fixture/toolbox/environment skips.

## Regression Tests

Existing M1A regressions remain 3/3 PASS.

`test/runM1B3DRegressionTests.m` contains six scenarios:

- 3D line;
- surface;
- mesh-like plot;
- changed view angle;
- explicit axis limits/aspect ratio;
- manual camera position/target/up vector.

`M2T-RUNTIME-005` covers the common missing-transform cause. Before its fix all
six scenarios failed on `x_viewtransform`; after the projection fix the first
five passed. `M2T-RUNTIME-006` separately captures stale manual-camera view
angles (`{-37.5}{30}` instead of approximately `{37.875}{27.759}`); it failed
before its focused fix. Final M1B result: 6/6 PASS.

## TeX Validation

The compact M1A matrix remains: 6/6 exports, 11/12 engine combinations PASS,
one expected raw-Unicode/pdfLaTeX limitation, and no unexpected failure.

The complete Golden candidate compile matrix found six deterministic generated
outputs rejected by both LuaLaTeX and pdfLaTeX:

| ACID | Function | TeX evidence |
|---:|---|---|
| 10 | `peaks_contourf` | `Missing } inserted` at `\end{axis}` |
| 28 | `stairsplot` | `Missing } inserted` at `\end{axis}` |
| 32 | `stemplot` | `Missing } inserted` at `\end{axis}` |
| 33 | `stemplot2` | `Missing } inserted` at `\end{axis}` |
| 77 | `areaPlot` | `Missing } inserted` at `\end{axis}` |
| 95 | `colorbarLabelTitle` | PGF colormap parser mismatch at `\end{axis}` |

These are classified `TEX FAILURE`, rejected from Golden approval, and retained
with both engine logs. M1B does not conceal or repair these newly exposed legacy
TeX/PGFPlots compatibility issues outside the scoped 3D work.

## Golden Baseline Status

`ACID.Octave.11.3.0.md5` **was not created**. Every new hash is traceable in
`results.tsv`, but the 81 compiling candidates still require case-specific
semantic/visual approval. Six outputs are rejected and 18 are not executable
fixtures. An approved Golden table must not contain placeholders for those
states; unapproved non-skipped cases must continue to fail hash comparison.

Future approval should update a case only after reviewing its generated TeX,
both compiler results, review PDF, native-render comparison, expected plot/label
semantics, and rationale. The four-level strategy is documented in
`docs/design/TEST_STRATEGY_2_0.md`; visual comparison preparation is in
`docs/design/VISUAL_VALIDATION.md`.

## MATLAB Validation Required

**MATLAB VALIDATION REQUIRED.** MATLAB was not installed and M1B makes no MATLAB
compatibility claim. MATLAB retains the existing `view(axesHandle)` path, but the
following shared parsing/Handle Graphics behavior still requires validation:

- M1A bar child selection and ColorBar `Axes` association/manual positioning;
- 3D automatic/manual aspect ratios and projection sizing;
- automatic and manual camera/view semantics, including axis direction;
- degenerate limits/camera diagnostics and perspective warning behavior;
- all M1A/M1B regressions, ACID, and TeX matrices.

The conceptual current/older-HG2/optional-HG1 matrix and required modern object
coverage are defined in `docs/validation/MATLAB_VALIDATION_PLAN.md`. MATLAB is a
release gate, not an automatic blocker for architecture prototyping.

## Remaining Risks

- Eighty-one Golden candidates await case-specific semantic/visual approval.
- Six deterministic exports produce invalid TeX with TeX Live 2026 /
  PGFPlots 1.18.2 and need focused product regressions before approval.
- Perspective and arbitrary camera roll are not represented by the M1B fix.
- Current 3D math is validated on Octave scenarios but not against MATLAB's
  transform across HG generations.
- Optional packages and graphics-toolkit differences can alter fixture coverage;
  capability reasons must remain visible.
- MD5 identity remains a regression signal, not proof of scientific correctness.

## Readiness for M2

Final quality record after all productive changes:

- `git diff --check`: PASS;
- ACID: 105 discovered, 0 pass, 87 Golden mismatches, 18 explicit skips;
- M1A regressions: 3/3 PASS;
- M1B 3D/camera regressions: 6/6 PASS;
- audit harness: 17 deterministic exports, one Octave histogram not testable;
- compact TeX subset: 6/6 exports, 11 engine PASS, one expected limitation,
  zero unexpected failures;
- M1B end-to-end smoke: export PASS, pdfLaTeX PASS, PDF 63,276 bytes;
- Golden review: 105 rows, 87 deterministic exports, 81 manual candidates,
  24 rejected/non-applicable states;
- approved Octave 11.3 Golden file: absent by design.

### CONDITIONAL GO FOR M2

The test infrastructure is stable, all Octave export deviations are classified,
the 3D compatibility root causes have focused green regressions, and Golden
approval state is traceable without blind updates. This is sufficient for
isolated M2 architecture prototyping.

Conditions:

1. Do not treat the absent Octave 11.3 Golden table as approved baseline.
2. Add focused semantic/TeX regressions and resolve or formally accept the six
   compile-rejected cases before their hashes can be approved.
3. Perform visual/native-vs-TikZ review for the 81 manual candidates.
4. Complete the MATLAB validation plan before release or compatibility claims.
5. Keep M2 prototypes behind existing public behavior until these gates provide
   cross-environment evidence.

No new IR, renderer architecture, public API, or plot type was implemented in
M1B.
