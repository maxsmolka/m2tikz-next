# M6.6 - Large-data export contract

## Baseline and decision

Started from clean public main `ffd4e755f5f4b4b02892b17a4033f1bd1dcf3309`
after M6.5 PR #9, exact head `0b859d93e44f6c60ec90dd947dc263e008dfda76`,
passed hosted run 35002397292, merged and its milestone branch was removed.
This phase uses `m6.6/large-data-contract`; latest release stays 0.5.0.

The default remains sample-preserving, with no silent reduction/downsampling,
size/color collapse, whole-figure rasterization or legacy fallback. Existing
finite decimal precision and hybrid image 8-bit channel encoding are explicitly
distinguished from source/IR preservation. No reduction API is introduced.
The visual audit required a mapped-color correctness fix, detailed below.
See [LARGE_DATA.md](docs/LARGE_DATA.md).

## Measurement method

The new `benchmarkModernLargeData` uses deterministic public-safe synthetic
data, validates original normalized arrays/marker sizes, counts emitted
coordinate/table rows, and verifies PNG dimensions and decoded quantized RGB.
PNG grayscale/palette storage optimizations are normalized before pixel
comparison; those storage variants are not data loss.

Native reader measurements: MATLAB R2026a Update 5 on Windows. The existing
historical statement remains: Validated with MATLAB R2026a Update 4 on Windows.
No new native Octave large-data reader claim is made. Portable Octave tests
use the same contract assertions on small IR-only fixtures.

Reader time includes reader validation; the separate validation column measures
an additional IR-only validation pass. Planner means backend selection; render
means combined PGFPlots plan/asset-array construction. Write includes TeX/PNG
output and PNG verification. Fixture creation is separate. CPU means the
runtime-reported process CPU delta for the render stage, not wall time or peak
memory. Figures below are observations, not medians, limits or guarantees.

## Native stage measurements

Seconds, rounded; final CPU-instrumented run after the color correction.
Sizes/counts were also verified in earlier runs. The final compiler lane uses
these exact generated files, not the earlier pre-correction artifacts.

| Case | Count | Fixture | Reader | IR validate | Planner | Render wall / CPU | Write |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Line | 100000 | 1.010 | 0.027 | 0.0008 | 0.0049 | 0.102 / 0.094 | 0.0076 |
| Constant scatter | 100000 | 0.853 | 0.023 | 0.0010 | 0.0019 | 0.088 / 0.094 | 0.0070 |
| Mapped scatter | 100000 | 0.841 | 0.012 | 0.0006 | 0.0010 | 1.764 / 1.813 | 0.0103 |
| Scalar 512 vector | 262144 | 0.837 | 0.011 | 0.0038 | 0.0014 | 3.711 / 3.750 | 0.0106 |
| Scalar 1024 vector | 1048576 | 0.791 | 0.010 | 0.0011 | 0.0043 | 15.073 / 15.047 | 0.0412 |
| Scalar 512 hybrid | 262144 | 0.864 | 0.011 | 0.0005 | 0.0008 | 0.028 / 0.016 | 0.0464 |
| Scalar 1024 hybrid | 1048576 | 0.867 | 0.008 | 0.0009 | 0.0011 | 0.060 / 0.234 | 0.0472 |
| RGB 512 hybrid | 262144 | 0.839 | 0.016 | 0.0025 | 0.0039 | 0.015 / 0.344 | 0.0271 |
| RGB 1024 hybrid | 1048576 | 0.857 | 0.018 | 0.0068 | 0.0075 | 0.019 / 0.031 | 0.0517 |
| Surface 129 x 129 | 16641 | 0.873 | 0.014 | 0.0020 | 0.0007 | 0.240 / 0.281 | 0.0032 |

An earlier repeat recorded a 1243.939-second scalar-1024 render wall time,
whereas the first run recorded 12.799 seconds and the CPU-instrumented rerun
13.581 seconds (13.547 CPU seconds), before the final 15.073-second run.
The cause of that outlier was not proven;
large wall-clock discontinuities were also observed during the session. It is
recorded, not silently removed or interpreted as a stable algorithmic cost.
CPU measurements are coarse for short operations and may include other runtime
threads. No shared-runner wall-clock threshold is derived from these samples.

## Products, compiler and memory boundary

Bytes are exact, not MiB. IR bytes are MATLAB `whos` variable footprint, **not
peak process RSS**, allocator cost, MATLAB/TeX total memory or a memory ceiling.
No reliable peak-memory claim is made. Compiler observations use Linux
LuaLaTeX 1.22 / TeX Live 2025/Debian, not native Windows TeX.

| Case | TeX bytes | PNG bytes | IR variable bytes | Compile seconds / outcome |
| --- | ---: | ---: | ---: | --- |
| Line 100k | 3932021 | 0 | 1611730 | 16.540 / PASS |
| Constant scatter 100k | 3932104 | 0 | 1612478 | 28.031 / PASS |
| Mapped scatter 100k | 6429393 | 0 | 2412480 | 63.338 / PASS |
| Scalar 512 vector | 7149439 | 0 | 2117362 | not attempted at full scale |
| Scalar 1024 vector | 28867458 | 0 | 8417010 | not attempted at full scale |
| Scalar 512 hybrid | 892 | 6653 | 2117362 | 1.076 / PASS |
| Scalar 1024 hybrid | 897 | 22606 | 8417010 | 1.100 / PASS |
| RGB 512 hybrid | 736 | 12426 | 6311656 | 1.142 / PASS |
| RGB 1024 hybrid | 741 | 40059 | 25194216 | 1.124 / PASS |
| Surface 129 x 129 | 865131 | 0 | 544226 | 3.181 / PASS |

All eight selected final full-size compiler runs completed within a shared
400-second external batch supervision limit; no timeout occurred. Earlier
pre-correction runs also passed with a 240-second per-process limit. The two large
vector images were measured through full row-preserving TeX generation, not
claimed as compiled. Small vector-image representatives compile in CI.
The highly repetitive synthetic RGB/scalar patterns compress unusually well;
their PNG sizes must not be extrapolated to arbitrary scientific images.
Representative full-size line, mapped scatter, RGB and surface PDFs were
rendered and visually inspected; cardinality/pixel assertions remain the
scientific data-preservation gate rather than a coarse preview image.

## Color correctness discovered by visual review

The two-color 100k scatter fixture revealed a pre-existing defect: interpolated
PGFPlots colormaps introduced purple where native MATLAB showed only blue or
red. Scalar scatter now resolves clipped discrete row indices before decimal
serialization and emits explicit symbolic classes, retaining the original
scalar column. Variable-size runs keep unique names and input point order.
Direct-access PGFPlots scatter was tested but fails in the installed engine;
the final implementation uses its supported symbolic-class mechanism.

Surface `FaceColor='interp'` requires interpolation of scalar values **before**
the discrete color lookup, not interpolation of mapped vertex RGB. Real native
two-color references exposed this distinction; the final surface renderer
uses piecewise-constant lookup with a full final interval. Colorbars use the
same finite intervals, including the last color. See the
[PGFPlots colormap specification](https://tikz.dev/pgfplots/reference-markers).
No IR data, geometry, schema or public option is changed by these corrections.

Six portable boundary/style/3-D/colorbar fixtures and four native MATLAB
scatter/scatter3/surface/image references supplement cardinality tests. The
native source/export colors were visually compared, including bin boundaries.
These checks establish the tested color semantics, not pixel-identical fonts,
ticks or general 3-D viewport sizing; the existing large whitespace in some
non-square 3-D viewports is not characterized as native geometry parity.

## Interpretation and next performance work

The measured native scalar-vector renderer dominates its reader/planner/write
stages and scales roughly with image-cell count in the uninterrupted samples.
Mapped-scatter serialization costs more than buffered constant coordinates.
These are concrete M6.8 optimization candidates, provided text/data semantics
are preserved. No optimization or precision change is made in M6.6 itself.

There is insufficient architecture for a trustworthy generic opt-in reducer:
extrema, gaps, uncertainty, ownership, styles and error bounds need explicit
contracts. A weak downsampling API is therefore deferred. Users receive
representation/resource guidance instead, with no automatic scientific choice.

## Tests, documentation and integration

Ten portable small-scale contract cases and ten real compiler cases exercise
the same paths without brittle timing assertions. The native full ten-case
matrix passed after exact table/coordinate/marker/pixel assertions were added.
CI retains the three protected job names and adds these focused lanes.
Each focused portable lane also runs six color regressions. Native regression
includes the previous 29 rich-scatter and 26 scientific-3-D cases, separately
from the ten large-data and four new native color references.
The inherited M0/M1A benchmark notes are labeled historical and linked to the
new modern contract. Status, roadmap, workflow, support and testing guidance
are aligned; release metadata remains 0.5.0.

## Acceptance decision

Focused and full-scale evidence is complete. The full portable regression
passed: public preview, all fifteen extended suites, previous security/tiled/
dual-Y/3-D foundations, and the new 10+6 contract and 10+6 compiler cases.
Six architecture invariants, documentation links, confidentiality, citation
(0.5.0), actionlint and diff checks passed. A final fixture-only spacing
adjustment keeps the horizontal colorbar preview readable and is retested.
Integration still requires all three hosted jobs green on the exact head, followed
by verified merge and branch cleanup before M6.7.
