# MATLAB validation matrix

The modern pipeline was validated locally with MATLAB R2026a Update 4 on
Windows (`26.1.0.3312084`, `win64`). This claim is limited to that release,
architecture, and operating system; it does not validate older or newer MATLAB
releases. GNU Octave 11.3 remains the public hosted-CI runtime.

| Capability | Octave 11.3 | MATLAB R2026a Update 4 on Windows | Status | Evidence |
| --- | --- | --- | --- | --- |
| Runtime/environment | validated | validated | validated | L0 |
| Line | validated | validated | validated | F01, F02 |
| Scatter | validated | validated | validated | F03, F06 |
| Errorbar | validated | validated | validated | F04, F05, F07 |
| Legend and ticks | validated | validated | validated | F08, F09 |
| Log/reversed axes | validated | validated | validated | F10, F11 |
| Manual/multiple axes | validated | validated | validated | F12-F14 |
| Colorbar | validated | validated | validated | F15, F16 |
| Shared elements | IR/renderer validated | IR/renderer validated | partial | F17 |
| Scalar images | validated | validated | validated | F18-F22, M3.3 H1-H18 |
| Publication profile | validated | validated | validated | F23, M3.1 public profile suite |
| Figure sets | validated | validated | validated | F24, M3.2 S1-S16 |
| Hybrid image backend | validated | validated | validated | F25, M3.4 R1-R24 |
| Automatic backend planner | validated | validated | validated | F26, M3.5 P1-P24 |
| RGB/alpha images | unsupported diagnostic | unsupported diagnostic | unsupported | M3.3 H15-H16, M3.5 P18-P19 |
| Axes-data user text | synthetic IR/renderer | runtime reader/export | supported in observed 2-D scope | M5.1 public synthetic suite |
| Figure-normalized arrow/double-arrow | synthetic IR/renderer | runtime reader/export | supported in observed scope | M5.1 public synthetic suite |
| Arbitrary annotation shapes | unsupported diagnostic | unsupported diagnostic | unsupported | M5.1 A12, NC4-NC5 |
| Grouped vertical bars | native reader/IR/renderer | native reader/export | supported in numeric-category, constant-style scope | M5.2 public synthetic suite |
| Stacked/horizontal/mapped-color bars | unsupported diagnostic | unsupported diagnostic | unsupported | M5.2 B20-B23, BNC3/BNC7-BNC10 |
| Vertical legacy boxplot | IR/renderer only (native package not provisioned) | native `boxplot` compound reader/export | supported in traditional/filled scope | M5.3 public synthetic suite |
| Horizontal/notched/other statistical charts | unsupported diagnostic | unsupported diagnostic | unsupported | M5.3 X20-X23, XNC4/XNC7-XNC10 |
| Legacy smoke | separately validated | separately validated | validated smoke | L11 |

F01-F26 pass 26/26 in two fresh MATLAB batch processes. The generated IR,
TeX, PNG, manifest, planner decision, PDF, and figure-lifecycle checks pass.
LuaLaTeX compilation succeeds with TeX Live 2026. The publication profile
produces 85 mm and 170 mm output within the 0.05 pt test tolerance. The visual
V01-V08 comparison passed human semantic review.

The authoritative executable registry is `m2t_test.fixtureRegistry`. Generated
evidence is written below `build/matlab-validation`; local diagnostic copies
may be retained below ignored `.audit/` paths. HG snapshots diagnose runtime
representation and are not equality goldens.

## Remaining qualification

- Hosted GNU Octave CI has not run against this unpushed branch. Full
  cross-platform confirmation therefore remains conditional on a green hosted
  run after review and push.
- The installed MATLAB trial exposed many optional MathWorks products. No
  optional-toolbox API was observed in the modern call paths, but a base-only
  installation was not available to prove the stronger phrase "Validated with
  base MATLAB only."
- Shared figure-level elements have IR/renderer coverage, not broad runtime
  reader coverage.
