# Large-data export contract

The default modern exporter retains every supported sample, matrix cell,
coordinate, size/color value and ownership relationship in normalized IR.
It does **not** automatically reduce, resample, bin, decimate, coalesce markers,
rasterize a whole figure or switch to the inherited exporter. Increasing point
count does not change that contract. `ImageBackend='vector'` remains the default.

## Representation is not reduction

- Lines and scatter retain all samples in inline TeX; repeated points and line
  discontinuities are not discarded. Per-point scatter size/color can grow
  command/style count substantially; unique RGB lookup and many size runs are
  not constant-cost operations.
- Scalar vector images retain one table row per cell and the original scalar
  value plus mapped index. Millions of cells therefore create large TeX input.
- Explicit `hybrid` preserves the image pixel dimensions, with vector axes and
  text. Existing PNG encoding uses 8-bit channels, not arbitrary-precision
  source samples. It is lossless with respect to the **quantized RGBA asset**,
  not a bitwise archival copy of arbitrary floating-point CData. Active alpha
  and supported color mapping retain their documented meanings.
- Explicit `auto` applies the existing deterministic image-only policy. It is
  not automatic line/scatter reduction. The default policy selects hybrid for
  dense scalar images above 4096 cells and for supported RGB/alpha images.
- Existing TeX numeric serialization uses 15 significant decimal digits. No
  additional precision reduction is introduced by large-data handling; binary
  double bitwise round-trip is not promised by that textual representation.
  Values near the finite-double maximum can round beyond that maximum; see
  [the precision boundary](DETERMINISM.md). TeX is not a source-data archive.

Thus the no-reduction/lossless-data policy means retained scientific samples
and normalized values, not an inaccurate promise of infinite display precision.
See [image backends](IMAGE_BACKENDS.md), [image plots](IMAGE_PLOTS.md) and
[backend planning](BACKEND_PLANNER.md) for representation-specific limits.

## Practical guidance

The M6.6 visual audit also corrected an existing mapped-color defect. Scalar
scatter resolves discrete colormap bins from original values before decimal
serialization and retains those values in a separate TeX column. Surfaces
interpolate scalar metadata before applying the discrete colormap; they do
not interpolate mapped vertex RGB. Colorbars show all finite color intervals.
This is a correctness fix, not sample aggregation or reduction. See the
[PGFPlots colormap contract](https://tikz.dev/pgfplots/reference-markers).

Use LuaLaTeX for supported exports. A successful read/render does not guarantee
that the TeX engine has enough resources for a very large document. Compilation
failure stays explicit; there is no silent retry with fewer points. Large
vector images are particularly expensive. Select hybrid deliberately when its
pixel/8-bit representation is appropriate, rather than expecting the exporter
to make that scientific decision for you.

There is no universal maximum sample count or guaranteed completion time.
Runtime, renderer, colormap, unique point styles, TeX installation and system
resources all matter. Measure representative data and preserve the source
figure/data for reproducibility. For long operations, use a supervised external
process limit when appropriate; the current public compiler has no timeout
option. Do not mistake variable-size measurements for peak process memory.

## Reproducible measurements

`benchmarks/benchmarkModernLargeData.m` measures 100k line, constant and mapped
scatter, 512/1024 scalar images with vector/hybrid plans, RGB images at both
sizes with hybrid, and a 129-by-129 scalar surface. It records fixture creation,
native reader (when selected), IR validation, backend planner, combined
render-plan/asset-array construction, file/PNG write, TeX/asset bytes and
optional compilation. `whos` IR variable bytes are labeled as such; no peak
RSS or memory-ceiling claim is made. Use a dedicated generated-output folder.

```matlab
addpath('benchmarks');
benchmarkModernLargeData(fullfile('.audit','large-native'),'native','full',false);
benchmarkModernLargeData(fullfile('.audit','large-ir'),'ir','full',false);
```

The fourth argument enables optional real compilation. Full-size scalar
vector-image compilation is deliberately skipped by this benchmark. Local
acceptance may separately supervise selected full-scale compiler runs and
record failures/timeouts honestly; they are observations, not flaky CI limits.
The native source lane measures the runtime actually used; `ir` never implies
native reader evidence. The new MATLAB measurements use R2026a Update 5 on
Windows. Portable small-scale Octave checks are separate evidence.

CI runs the same cardinality/pixel assertions on 101-point, 8/16-image and
9-square-surface fixtures plus real small-scale compilation. Timing values
are never pass/fail thresholds. The [M6.6 report](../M2TIKZ_NEXT_M6_6_LARGE_DATA_CONTRACT_REPORT.md)
contains observed numbers and their scope; synthetic repetitive image sizes
are not representative compression guarantees for real-world imagery.

## Reduction API decision

No pre-1.0 reduction API is introduced. A credible future API would need
explicit domain error bounds, extrema/gap/uncertainty preservation, ownership
and color/size handling, reproducible algorithms and disclosed provenance.
Current evidence supports clear representation guidance, not a weak universal
downsampler. M6.8 buffers the measured scalar vector-image serialization
bottleneck with byte-identical output and unchanged scientific semantics.
