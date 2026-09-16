# MATLAB validation matrix

M7.1 adds 18 portable stored-IR contract cases and nine real PDF compilations
in both native MATLAB R2026a Update 5 and Octave 11.3. Nine canonical JSON
goldens match byte-for-byte across these observed runtimes. Native MATLAB
compilation again uses the Linux LuaLaTeX bridge. This is schema/codec/renderer
evidence, not expanded MATLAB or native Octave graphics-family support.
See [FIGURE_IR.md](FIGURE_IR.md).

M7.0 adds eight public API-freeze contract cases in native MATLAB R2026a
Update 5 on Windows and GNU Octave 11.3. Both pass with real LuaLaTeX:
the Windows MATLAB run uses a temporary Linux TeX Live 2025/Debian bridge.
This validates the public workflows, not new graphics families or other
MATLAB releases. See [API.md](API.md).

The modern pipeline was validated locally with MATLAB R2026a Update 4 on
Windows (`26.1.0.3312084`, `win64`). This claim is limited to that release,
architecture, and operating system; it does not validate older or newer MATLAB
releases. GNU Octave 11.3 remains the public hosted-CI runtime.

Separate newer evidence collected from 2026-09-13: S1 path/security checks and M6.3 fixed
tiled layouts were tested with MATLAB R2026a Update 5 on Windows. M6.3 includes
28 native cases, three native-workflow cases using Linux LuaLaTeX through a local
bridge, and separate native-generated/portable TeX and visual checks. These
results do not relabel the historical Update 4 matrix below or claim native
Windows TeX or native Octave tiledlayout support. See [TILED_LAYOUTS.md](TILED_LAYOUTS.md).

M6.4 adds separate Update 5 native dual-Y reader/lifecycle and real-compiler
workflow tests, plus portable Octave IR and TeX/PDF tests. These are not additions
to the historical Update 4 column below. See [DUAL_Y_AXES.md](DUAL_Y_AXES.md).

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
| Rich 2-D scatter | native reader/IR/renderer | native reader/IR/renderer | supported in bounded size/color/edge/face scope | M6.1 focused suite, 29/29 per observed runtime |
| RGB/alpha images and direct scalar mapping | native reader/IR/renderer | native reader/IR/renderer | supported in bounded M6.2 scope; rich modes require hybrid | M6.2 focused suite, 26/26 per observed runtime; 11 focused TeX exports |
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

M6.8 adds eight deterministic/reference tests in MATLAB R2026a Update 5 on
Windows and five real workflow checks over five native figures (including
tiled, dual-Y and scatter3). Octave has the same eight checks and five workflows
over two common figures; a generated German locale is checked separately.
Ten native full-scale before/after fixtures retain identical TeX and PNG bytes.
See [determinism and precision boundaries](DETERMINISM.md).

M6.7 adds a separate MATLAB R2026a Update 5 on Windows capability matrix
(50 cases), nine real public export/compiler workflows, and 211 native
regression cases across bars, boxplots, surfaces, rich scatter/images, tiled
layouts, dual Y and scientific 3-D. Fixtures use explicit white source styling
where needed to isolate property guards from theme defaults. Real compilation
uses a Linux LuaLaTeX bridge, not an asserted native Windows TeX installation.
The corresponding Octave matrix has 52 cases, including compound patch
tampering and large-scatter runtime representation; these counts are distinct
from the portable IR regression. See [the policy](UNSUPPORTED_POLICY.md).

M6.5 has separate MATLAB R2026a Update 5 on Windows evidence: 26 focused native
scatter3/mesh/camera/lifecycle/negative cases, four real public profile/set
exports, 19 portable IR cases and seven portable TeX documents. Thirteen native
generated documents were compiled separately with Linux LuaLaTeX and inspected
against synthetic source figures. This does not broaden the historical Update
4 matrix above or establish native Octave 3-D parity. See [SCIENTIFIC_3D.md](SCIENTIFIC_3D.md).

- GNU Octave 11.3 is the hosted Linux CI baseline; results on other Octave
  releases or platforms are not implied.
- The installed MATLAB trial exposed many optional MathWorks products. No
  optional-toolbox API was observed in the modern call paths, but a base-only
  installation was not available to prove the stronger phrase "Validated with
  base MATLAB only."
- Shared figure-level elements have IR/renderer coverage, not broad runtime
  reader coverage.
