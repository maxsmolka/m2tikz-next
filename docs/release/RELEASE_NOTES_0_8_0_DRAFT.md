# m2tikz-next 0.8.0 - draft release notes

**Unreleased feature-freeze candidate.** These notes are prepared for a separate
release review. There is no authorized 0.8.0 tag, release date or GitHub Release.
The latest published release and CITATION version remain 0.5.0.

## Development highlights since 0.5.0

- Rich 2-D scatter and bounded rich image/alpha semantics retain per-point and
  per-pixel roles, with explicit vector/hybrid/auto policy.
- Fixed MATLAB tiled layouts, bounded dual-Y axes and bounded scatter3/wire
  mesh extend scientific workflows without general scene-graph claims.
- Unsupported-content, ownership, numeric precision and large-data contracts
  prefer explicit diagnostics to incomplete output or silent reduction.
- The two existing public APIs have a freeze-candidate contract; FigureIR v2
  has backward-readable defaults, strict migration and canonical persistence.
- Runtime property handling, scalar strings, explicit UTF-8, path/PNG-write
  diagnostics and observed cross-environment reproducibility are hardened.

No single heading expands the narrow [support matrix](../SUPPORT.md). See the
[unreleased changelog](../../CHANGELOG.md) for milestone detail and
[installation](../INSTALLATION.md) for setup. Real PDF compilation requires
LuaLaTeX/TikZ/PGFPlots/standalone; compilation is not a visual-fidelity proof.

## Evidence and limits

Validated with MATLAB R2026a Update 4 on Windows.

That historical statement is retained. Later milestones separately validate
R2026a Update 5 on Windows and GNU Octave 11.3 on Linux. Native reader, portable
IR, renderer, real TeX and visual evidence are distinct. A different MATLAB
version and real external scientific figures are the next acceptance work,
not a predeclared success. See [runtime](../RUNTIME_COMPATIBILITY.md) and
[environment](../ENVIRONMENT_CONTRACT.md) contracts.

Known limits include dynamic/nested/zero-spacing tiled layouts, broad dual-Y
variants, arbitrary 3-D scenes and camera/material/lighting behavior, scatter
alpha, arbitrary annotation/patch/bar/boxchart families, nonwhite axes,
automatic reduction and a built-in compiler timeout. Hybrid channels are
8-bit; scientific TeX is 15-significant-digit text rather than a binary archive.
Cross-encoder PNGs and cross-engine PDFs need not have identical bytes.

## Feature freeze and next work

The [freeze policy](FEATURE_FREEZE_0_8_0.md) allows correctness, diagnostics,
compatibility/portability, performance-regression, documentation/security and
release-engineering work. New major families require a critical demonstrated
acceptance gap. Public API changes are exceptional and need migration review.

The eventual release is source-first and retains all upstream attribution and
license material. No private test figures, datasets, machine details, logs or
generated local build directories belong in release artifacts.
