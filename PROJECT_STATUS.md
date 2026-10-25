# Project status

Latest released version: **0.8.2**, the pre-1.0 acceptance patch following the
0.8.0 feature freeze. It includes upper/lower horizontal legends, the profile gallery,
native MATLAB smoke test and internal compiler deadlines. See
[release notes](docs/release/RELEASE_NOTES_0_8_2.md) and [CHANGELOG.md](CHANGELOG.md).

## Corrections since v0.8.0

- PR #21 added bounded horizontal/multicolumn legends above one logical 2-D
  axes, including publication spacing and explicit overflow failure. This is
  not in the immutable v0.8.0 tag; see [legend layout](docs/LEGENDS.md).
- The [MATLAB profile gallery](examples/13-profile-gallery/README.md) compares
  four synthetic figures without a profile, at 85 mm and at 170 mm, producing
  12 exports and four editable `.fig` sources. The native MATLAB smoke test
  checks products, size metadata, saved sources and caller/figure lifecycle.
- Focused development evidence uses MATLAB R2026b on Windows and a Linux
  LuaLaTeX bridge. Hosted CI is still Octave/Linux; neither this evidence nor
  compilation success qualifies MATLAB R2022a or native Windows MiKTeX.
- Compiler discovery/compilation have internal 15/300-second process budgets,
  owned process-group/Job cleanup and distinct timeout/supervisor diagnostics.
  POSIX needs Python 3; Windows uses Windows PowerShell/.NET. The public API
  options and schemas are unchanged; this is not an end-to-end timing promise.

External testing should [pin the intended release or corrected commit](docs/validation/EXTERNAL_ACCEPTANCE_TESTING.md).
Still pending: external scientific/visual acceptance on the tester's actual
runtime and TeX installation and feedback triage before RC readiness. The patch
does not complete external acceptance or broaden runtime-support claims.

## Current contract

Version 0.8.2 adds lower `southoutside` legends under the
existing one-logical-2-D boundary, including two rows and source/publication
exports. See [legend layout](docs/LEGENDS.md). The v0.8.1 tag is unchanged and
does not contain this lower placement.

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

Current release validation: MATLAB R2026a Update 5 on Windows.

Historical Update 4 milestone records remain unchanged. This is not a claim for all MATLAB
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
The [environment contract](docs/ENVIRONMENT_CONTRACT.md) defines explicit UTF-8,
path/process/TeX boundaries, stable asset-write diagnostics and cross-runtime
JSON/TeX goldens. PNG pixels, not cross-encoder bytes, are the scientific
comparison; native Windows TeX and other MATLAB versions remain unverified.
The [0.8.0 feature-freeze policy](docs/release/FEATURE_FREEZE_0_8_0.md) is now
in force; see the finalized [release notes](docs/release/RELEASE_NOTES_0_8_0.md).
No new major graphics family is planned before 1.0 unless real
external acceptance reveals a critical correctness/usability gap that cannot
reasonably be deferred. Fixes, diagnostics, compatibility, portability,
performance-regression fixes, docs, security and release engineering remain
in scope; speculative features and unrelated API expansion do not.
The [external acceptance package](docs/validation/EXTERNAL_ACCEPTANCE_TESTING.md)
provides a local-only helper, manual semantic checklist and redacted feedback
template. It is not a new public API or evidence that external testing occurred.
Next is **external real-world MATLAB acceptance**, then feedback triage, as
ordered in [ROADMAP.md](ROADMAP.md).
New MATLAB object support requires native MATLAB
validation. See [ARCHITECTURE.md](ARCHITECTURE.md) for implementation boundaries.
