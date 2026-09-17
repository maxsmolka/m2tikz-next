# Roadmap to 1.0

Latest release: 0.5.0. Functionality merged through M7.3. This roadmap defines
ordered acceptance work, not release dates or claims that planned features are
already supported. Each milestone requires its own review and successful
`repository-policy`, `octave-tests`, and `tex-preview` checks before merge.

## Foundation work through M7.3

| Phase | Scope and acceptance boundary |
| --- | --- |
| Post-M6.2 alignment | Complete: released/development features, architecture, status, workflow, and testing documentation aligned. |
| S1 | Security foundation: repository protection, workflow pins, product preflight, nonrecursive asset cleanup, compiler arguments and explicit text/TeX trust boundary. |
| M6.3 | Fixed layouts implemented with explicit cells/spans/order, shared labels, bounded spacing/padding, axes-owned decorations and profiles; see docs/TILED_LAYOUTS.md for native evidence and exclusions. |
| M6.4 | Implemented bounded left/right ownership, independent scales/ticks/labels/colors, shared X, linked legends and supported tiled/profile interactions; see docs/DUAL_Y_AXES.md for native evidence and exclusions. |
| M6.5 | Implemented bounded rich scatter3, constant-color wire meshes, explicit orthographic camera/depth/child-order semantics; native and portable evidence with limits in docs/SCIENTIFIC_3D.md. |
| M6.6 | Defined no-reduction large-data contract with explicit encoding precision, 100k-point/512-1024-image/129-square-surface measurements and count/pixel CI assertions; no weak reduction API or wall-clock gate. See docs/LARGE_DATA.md. |
| M6.7 | Hardened traversal, semantic-property guards, linked legends/colorbars and compound geometry; native negative/positive matrix and real compiler workflows. Explicit unsupported/presentation policy in docs/UNSUPPORTED_POLICY.md. |
| M6.8 | Audited IR/JSON/TeX/planning/diagnostics/assets/manifests, locale and ordered layouts. Measured scalar-image buffering preserves exact prior bytes; precision/encoder boundaries and repeated native exports are documented in docs/DETERMINISM.md. |
| M7.0 | API-freeze candidate audited and documented in docs/API.md; real public-contract tests cover defaults/results/failures/sets. No breaking cleanup. Future breaking changes are exceptional and require an ADR and migration notes. |
| M7.1 | Complete: FigureIR v2 compatibility/default/ownership policy, strict v1 migration, future-version rejection, deterministic numeric JSON codec and nine golden replay/PDF classes. See docs/FIGURE_IR.md and ADR-0025. |
| M7.2 | Runtime-sensitive reader audit, absence-only optional-property defaults, scalar string normalization and R01-R15 native/portable/real-compiler coverage. MATLAB Update 5 and Octave 11.3 are separate observed environments; see docs/RUNTIME_COMPATIBILITY.md. |
| M7.3 | Explicit UTF-8/environment contract, observed Unicode/spaced/nested paths, stable PNG-write diagnostics, real compiler failures and common canonical JSON/TeX goldens. See docs/ENVIRONMENT_CONTRACT.md; no native Windows TeX or untested runtime claim. |

The supported/unsupported contract, scientific fidelity, deterministic output,
secure workflow, bounded performance, and explicit compatibility take priority
over maximum graphics coverage. Reader semantics belong in handle-free IR;
renderers cannot inspect runtime graphics handles. No whole-figure raster or
legacy fallback is permitted. Any unavailable correctness/native-runtime gate
blocks acceptance of the affected work.

## After M7.3

The [0.8.0 feature-freeze candidate preparation](docs/release/FEATURE_FREEZE_0_8_0.md)
is complete; no 0.8.0 release or tag is implied. After this candidate no new
major graphics family is planned before 1.0 unless external acceptance testing
reveals a critical correctness/usability gap that cannot reasonably be deferred.
Bug/correctness fixes, diagnostics, compatibility/portability, performance
regressions, docs/security/release engineering and narrowly necessary real
acceptance gaps remain in scope. Missing plot families, speculative features
and unrelated API expansion are not automatically authorized.

1. External acceptance package
2. External real-world MATLAB acceptance
3. Feedback triage
4. M8.0 1.0 release-candidate readiness
5. v0.9.0 / v1.0.0-rc.1
6. M8.1 RC burn-in
7. v1.0.0

Release/tag creation is a separate authorized action. Arbitrary scene graphs,
lighting/materials, texture mapping, arbitrary transparency, unfaithful
perspective, arbitrary patch topology, and volume rendering may remain explicit
1.0 non-goals. See [current status](PROJECT_STATUS.md) and
[support boundaries](docs/SUPPORT.md).
