# Project status

Latest released version: **0.5.0**. Merged development functionality extends
through **M6.6**. Unreleased features are listed separately in
[CHANGELOG.md](CHANGELOG.md); this status does not announce a new release.

## Current contract

The public APIs are `m2t.export` and `m2t.exportSet`. They provide deterministic
scientific TeX export, LuaLaTeX compilation, structured diagnostics, optional
publication profiles, and explicit figure sets. Public APIs remain pre-1.0;
`m2t2.*` and FigureIR are internal/experimental.

Supported families include 2-D lines, rich 2-D scatter, error bars, legends,
custom ticks, logarithmic/reversed axes, multiple/manual axes, scalar images,
bounded RGB/alpha image layers, colorbars, axes-owned text, figure arrows,
grouped vertical bars, narrow traditional boxplots, fixed tiled layouts with
bounded spans/shared labels, bounded dual Y line/scatter axes and narrow orthographic
Surface/Line3/Patch3 scenes, bounded rich scatter3 and constant-color wire mesh.
Each family has limits in
[SUPPORT.md](docs/SUPPORT.md).

Major remaining limitations include dynamic/nested/zero-spacing tiled layouts,
outer-tile decorations, dual-Y variants beyond the bounded contract,
general 3-D scenes, lighting/materials, scatter transparency, arbitrary
annotations/patches, broad bar/boxchart semantics, and automatic downsampling.
Hybrid images preserve pixel dimensions but encode channels at 8-bit precision.

## Evidence boundary

Validated with MATLAB R2026a Update 4 on Windows.

That is the existing recorded MATLAB evidence, not a claim for all MATLAB
versions or platforms. GNU Octave 11.3 is the hosted Linux CI baseline.
Native MATLAB, native Octave, portable IR/renderer, and TeX/PDF/visual evidence
are separate claims; portable fixtures do not imply native runtime support.
See the [validation matrix](docs/MATLAB_VALIDATION_MATRIX.md) and
[runtime differences](docs/MATLAB_OCTAVE_DIFFERENCES.md).

The M6.2 report records 140 Public Preview core cases, 233 extended portable
cases, 26 focused image cases in each observed runtime, and 11 focused TeX
exports. These are recorded milestone results; each subsequent milestone must
run its own acceptance gates. Required hosted jobs are `repository-policy`,
`octave-tests`, and `tex-preview`.

## Next phase

The alignment, S1 security hardening, bounded tiled layouts and explicit dual
Y axes and bounded scientific 3-D establish the current foundation.
The [large-data contract](docs/LARGE_DATA.md) retains all samples with explicit
representation limits and no reduction API. Next is **M6.7: unsupported-object
and partial-output hardening**, followed by the ordered work in
[ROADMAP.md](ROADMAP.md). New MATLAB object support requires native MATLAB
validation. See [ARCHITECTURE.md](ARCHITECTURE.md) for implementation boundaries.
