# Changelog

This file records user-visible m2tikz-next development. The complete inherited
matlab2tikz release history remains available in Git history and in the original
upstream repository; those releases are not m2tikz-next releases.

## m2tikz-next preview development

### Unreleased — target `v0.1.0-preview.1`

#### User-visible changes

- Added the experimental `m2t2.export(...)` path with versioned normalized IR,
  deterministic PGFPlots rendering, and explicit diagnostics.
- Added line, constant-style scatter, errorbar, multiple-axes/layout, colorbar,
  shared-element IR/renderer, and JSON migration/replay foundations.
- Added Octave/TeX validation, curated examples, portable validation commands,
  and public-preview repository checks.
- Kept the inherited `matlab2tikz(...)` API separate and unchanged in routing.
- Documented that MATLAB compatibility remains unvalidated.

#### Development milestones

- M1 stabilized the inherited runtime and established Octave/Golden baselines.
- M2 introduced the line IR architecture and handle-free renderer.
- M2.1 added heterogeneous series and axes semantics.
- M2.2 added multiple-axes and layout foundations.
- M2.3 added colorbars and figure-level elements.
- M2.4 prepared identity, licensing, repository hygiene, documentation, CI, and
  preview validation.

Detailed milestone reports are retained under `docs/development/`.
