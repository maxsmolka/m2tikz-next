# Roadmap to 1.0

Latest release: 0.5.0. Functionality merged through M6.2. This roadmap defines
ordered acceptance work, not release dates or claims that planned features are
already supported. Each milestone requires its own review and successful
`repository-policy`, `octave-tests`, and `tex-preview` checks before merge.

## Foundation work through M7.1

| Phase | Scope and acceptance boundary |
| --- | --- |
| Post-M6.2 alignment | Complete: released/development features, architecture, status, workflow, and testing documentation aligned. |
| S1 | Security foundation: repository protection, workflow pins, product preflight, nonrecursive asset cleanup, compiler arguments and explicit text/TeX trust boundary. |
| M6.3 | Bounded fixed tiled layouts: explicit tile/span/order/ownership, shared labels, supported spacing/padding and legend/colorbar placement; native MATLAB acceptance mandatory. |
| M6.4 | Explicit left/right Y-axis ownership, scales/ticks/labels, shared X, legends and supported layout interactions; native MATLAB acceptance mandatory. |
| M6.5 | Bounded scientific scatter3, mesh-like surfaces and combinations with faithful views/color mapping; native evidence for new MATLAB object claims. |
| M6.6 | Lossless large-data contract and synthetic line/scatter/image/3-D benchmarks; no silent reduction and no brittle wall-clock CI gate. An opt-in reduction API may remain deferred. |
| M6.7 | Unsupported-object/partial-output hardening: explicit classification for relevant objects/properties, stable diagnostics, no successful materially incomplete output. |
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
