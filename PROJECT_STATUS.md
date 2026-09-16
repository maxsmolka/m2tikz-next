# Project status

Latest released version: **0.5.0**. Merged development functionality extends
through **M7.2**. Unreleased features are listed separately in
[CHANGELOG.md](CHANGELOG.md); this status does not announce a new release.

## Current contract

The public APIs are `m2t.export` and `m2t.exportSet`. They provide deterministic
scientific TeX export, LuaLaTeX compilation, structured diagnostics, optional
publication profiles, and explicit figure sets. They are the pre-1.0
[API-freeze candidate](docs/API.md); breaking changes now require exceptional
justification, an ADR and migration notes. No breaking cleanup was necessary;
`m2t2.*` remains internal/experimental. Stored FigureIR v2 follows the
[explicit compatibility contract](docs/FIGURE_IR.md), with safe v1 migration,
golden replay, deterministic JSON and explicit future-version rejection.

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
representation limits and no reduction API. The [unsupported-content policy](docs/UNSUPPORTED_POLICY.md)
now rejects unrepresented properties, ambiguous ownership and modified compound
data before producing misleading partial output. Nonwhite axes backgrounds,
unresolved multi-object 3-D depth sorting and inconsistent scatter compounds
are explicit unsupported cases. [Determinism and precision boundaries](docs/DETERMINISM.md)
are audited; buffered scalar-image serialization retains exact prior TeX bytes.
The [runtime compatibility contract](docs/RUNTIME_COMPATIBILITY.md) records
required source properties, preserved runtime-specific dependencies, explicit
optional-property handling and the R01-R15 synthetic evidence layers. New
M7.2 evidence uses MATLAB R2026a Update 5 on Windows and Octave 11.3/gnuplot;
no additional MATLAB version or platform is implied.
Next is **M7.3: Portability and environment contract**, followed by the ordered work in
[ROADMAP.md](ROADMAP.md). New MATLAB object support requires native MATLAB
validation. See [ARCHITECTURE.md](ARCHITECTURE.md) for implementation boundaries.
