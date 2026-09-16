# Roadmap to 1.0

Latest release: 0.5.0. Functionality merged through M6.7. This roadmap defines
ordered acceptance work, not release dates or claims that planned features are
already supported. Each milestone requires its own review and successful
`repository-policy`, `octave-tests`, and `tex-preview` checks before merge.

## Foundation work through M7.1

| Phase | Scope and acceptance boundary |
| --- | --- |
| Post-M6.2 alignment | Complete: released/development features, architecture, status, workflow, and testing documentation aligned. |
| S1 | Security foundation: repository protection, workflow pins, product preflight, nonrecursive asset cleanup, compiler arguments and explicit text/TeX trust boundary. |
| M6.3 | Fixed layouts implemented with explicit cells/spans/order, shared labels, bounded spacing/padding, axes-owned decorations and profiles; see docs/TILED_LAYOUTS.md for native evidence and exclusions. |
| M6.4 | Implemented bounded left/right ownership, independent scales/ticks/labels/colors, shared X, linked legends and supported tiled/profile interactions; see docs/DUAL_Y_AXES.md for native evidence and exclusions. |
| M6.5 | Implemented bounded rich scatter3, constant-color wire meshes, explicit orthographic camera/depth/child-order semantics; native and portable evidence with limits in docs/SCIENTIFIC_3D.md. |
| M6.6 | Defined no-reduction large-data contract with explicit encoding precision, 100k-point/512-1024-image/129-square-surface measurements and count/pixel CI assertions; no weak reduction API or wall-clock gate. See docs/LARGE_DATA.md. |
| M6.7 | Hardened traversal, semantic-property guards, linked legends/colorbars and compound geometry; native negative/positive matrix and real compiler workflows. Explicit unsupported/presentation policy in docs/UNSUPPORTED_POLICY.md. |
| M6.8 | Determinism across IR/JSON/TeX/planning/diagnostics/assets/manifests and locale/order; optimize only measured bottlenecks without changing scientific meaning. |
| M7.0 | Public API freeze candidate: document signatures/options/defaults/results/failures/output conventions in docs/API.md. Necessary breaking cleanup needs an ADR and migration notes. |
| M7.1 | FigureIR compatibility contract: optional defaults, missing/unknown fields, schema changes, deterministic migrations, explicit future-version rejection, and synthetic JSON compatibility fixtures in docs/FIGURE_IR.md. |

The supported/unsupported contract, scientific fidelity, deterministic output,
secure workflow, bounded performance, and explicit compatibility take priority
over maximum graphics coverage. Reader semantics belong in handle-free IR;
renderers cannot inspect runtime graphics handles. No whole-figure raster or
legacy fallback is permitted. Any unavailable correctness/native-runtime gate
blocks acceptance of the affected work.

## After M7.1

1. M7.2 MATLAB compatibility expansion
2. M7.3 Octave compatibility expansion
3. v0.8.0 feature-freeze candidate
4. M8.0 1.0 release-candidate readiness
5. v0.9.0 / v1.0.0-rc.1
6. M8.1 RC burn-in
7. v1.0.0

Release/tag creation is a separate authorized action. Arbitrary scene graphs,
lighting/materials, texture mapping, arbitrary transparency, unfaithful
perspective, arbitrary patch topology, and volume rendering may remain explicit
1.0 non-goals. See [current status](PROJECT_STATUS.md) and
[support boundaries](docs/SUPPORT.md).
