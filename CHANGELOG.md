# Changelog

This file records user-visible m2tikz-next changes. Original matlab2tikz
release history remains in Git history and the upstream repository; those
versions are not m2tikz-next releases.

## [Unreleased]

### Added

- M7.1: FigureIR compatibility policy, nine synthetic input/canonical JSON
  pairs, strict known-version migration and an internal deterministic JSON
  codec that preserves single NaN gaps and extreme double values. Malformed
  missing payload/ownership and ambiguous bare null now fail explicitly.
  No public API, TeX precision or manifest schema change. See docs/FIGURE_IR.md.

- M7.0: public API-freeze candidate contract and real compiler-backed API
  regression tests; no breaking changes or new aliases. See docs/API.md.

- M6.8: determinism/precision audit and real repeated/cross-directory export
  tests, including native tiled/dual/3-D sets and explicit PNG/JSON boundaries.
  See docs/DETERMINISM.md.

- M6.6: modern large-data stage benchmark and cardinality/pixel contract tests;
  explicit no-reduction guidance. No new reduction API. See docs/LARGE_DATA.md.

- M6.5: rich scatter3, explicit wire-mesh topology and bounded orthographic
  camera/depth/child-order semantics. See docs/SCIENTIFIC_3D.md.

- M6.1: rich 2-D scatter with constant/per-point sizes, per-point RGB or
  scalar-mapped colors, bounded edge/face modes, and axes-owned colorbars.
- M6.2: scalar scaled/direct images, truecolor RGB, and bounded constant or
  per-pixel image alpha; rich modes use image-layer hybrid PNG output.
- M6.3: fixed MATLAB tiled layouts with explicit cells/spans, shared labels,
  axes-owned decorations and profile gutters; dynamic/nested/zero-spacing and
  outer-tile decoration cases fail explicitly. See docs/TILED_LAYOUTS.md.
- Architecture, project status, and roadmap documents distinguish merged
  development capabilities from the latest released version.
- M6.4: bounded native MATLAB dual Y axes, explicit series/ruler ownership,
  linked legend ordering, independent scales/ticks/colors and shared X;
  colorbar/tiled/profile integration. See docs/DUAL_Y_AXES.md.

### Fixed

- M6.8: measured large scalar vector-image serialization is buffered by row,
  preserving exact previous TeX bytes with no reduction or precision change.

- M6.7: actual legend object links preserve subsets/reordering; Octave
  colorbars retain real ticks/direction/labels; matching tags cannot hide text.
  Unknown/hidden children, datatips, brushing, modified bar/errorbar/boxplot
  compounds and unrepresented properties fail before successful partial output.

- M6.6 visual benchmark audit: scalar scatter and surface colors, including
  finite colorbar bins, follow MATLAB's discrete colormap instead of adding
  colors by interpolating colormap entries. Scatter retains original scalar
  values alongside explicit mapped classes in TeX.

- Rich per-point RGB/size runs now own distinct color/class names, avoiding
  color replacement during deferred PGFPlots 3-D drawing.

- Rich scatter marker roles no longer inherit PGFPlots cycle-list colors.
  Explicitly absent edges/faces remain absent in compiled filled markers;
  this defect was exposed by M6.4 native PDF review.

### Compatibility and validation

- M6.7: automatic orthographic camera and explicit multi-object child-order
  requirements now cover all native 3-D readers. Nonwhite axes, transparent
  axes on nonwhite canvases and inconsistent scatter compounds are rejected.
  One-row/column scalar vector images fail during planning; explicit hybrid
  preserves their pixels. See docs/UNSUPPORTED_POLICY.md for the tightened
  boundary and the separately recorded MATLAB Update 5/Octave evidence.
  Optional BarIR `xBounds` retains validated Octave rectangle boundaries;
  absent fields retain historical portable-IR geometry.
  Optional AxesIR `background` distinguishes white and transparent overlays;
  dual-Y data/ruler helper layers remain transparent.

- S1: product-path preflight, nonrecursive asset cleanup, safer filename/asset
  serialization, disabled compiler shell escape, pinned checkout Actions, and
  strengthened public repository protection. Unsafe or redirected products now
  fail explicitly; MATLAB output inspection requires a JVM. See SECURITY.md.

- Public options remain unchanged. FigureIR v2 gains additive defaults for
  older scatter and image documents. No automatic downsampling is introduced.
- M6.1/M6.2 evidence covers GNU Octave 11.3, MATLAB R2026a Update 4 on Windows,
  portable IR/renderer cases, and focused LuaLaTeX/PDF validation separately.
- See [support status](docs/SUPPORT.md) for the current capability boundaries.
  The limitations below describe the released 0.5.0 snapshot only.

## [0.5.0]

### Added

- Public `m2t.export` workflow for analysis, deterministic TeX export,
  LuaLaTeX compilation, PDF validation, and structured results.
- `m2t.exportSet` for deterministic multi-figure builds and manifests.
- Opt-in `publication` profile with single- and double-column sizing.
- Versioned normalized IR, JSON migration/roundtrip, and handle-free PGFPlots
  rendering.
- Evidence-backed support for core line, constant-style scatter, error-bar,
  axes/layout, legend, colorbar, scalar-image, annotation, grouped-bar,
  traditional boxplot, and narrow scientific 3-D workflows.
- Vector, hybrid, and opt-in deterministic automatic image-backend planning.
- Generic examples, portable validation commands, and hosted Octave/TeX CI.

### Changed

- End-user documentation now presents `m2t.*` as the public workflow and
  classifies `m2t2.*` as internal/experimental implementation interfaces.
- Unsupported scientific content is documented and diagnosed explicitly rather
  than being silently omitted.
- The inherited `matlab2tikz(...)` entry point remains separate and is not
  redirected to the modern pipeline.

### Validation

- GNU Octave 11.3 is exercised in hosted Linux CI.
- MATLAB validation is limited to MATLAB R2026a Update 4 on Windows.
- TeX preview validation uses TeX Live 2026, LuaLaTeX, and PGFPlots 1.18.x.

### Known limitations

- Version 0.5.0 is pre-1.0; public APIs and schemas may still change.
- Unsupported areas include per-point scatter semantics, tiled layouts,
  `yyaxis`, polar plots, broad annotation/patch/bar/boxchart behavior, general
  3-D scenes, broad transparency, and general downsampling.
- Runtime validation outside the exact environments above is not yet claimed.
