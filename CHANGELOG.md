# Changelog

This file records user-visible m2tikz-next changes. Original matlab2tikz
release history remains in Git history and the upstream repository; those
versions are not m2tikz-next releases.

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
