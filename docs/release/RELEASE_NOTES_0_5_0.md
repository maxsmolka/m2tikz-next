# m2tikz-next 0.5.0

m2tikz-next 0.5.0 is the first public pre-1.0 preview/beta of a modern,
validated scientific figure export pipeline derived from matlab2tikz. It is an
independent project and is not an official matlab2tikz release or successor.

## Highlights

- deterministic standalone PGFPlots and PDF export through `m2t.export`;
- reproducible figure-set builds and manifests through `m2t.exportSet`;
- opt-in `publication` profile with single- and double-column sizing;
- line, constant-style scatter, error-bar, axes/layout, legend, colorbar,
  scalar-image, annotation, grouped-bar, traditional boxplot, and narrow
  scientific 3-D workflows;
- vector, hybrid, and opt-in deterministic automatic image backends;
- structured diagnostics for unsupported scientific content.

## Installation

Clone the source repository, add `src` to the MATLAB or Octave path, and ensure
LuaLaTeX, TikZ, PGFPlots, and the `standalone` class are available. See the
[installation guide](../INSTALLATION.md) for exact runtime and TeX checks.

## Quick Start

```matlab
addpath('src');
x = linspace(0, 2*pi, 200);
y = sin(x);
figure;
plot(x, y);
result = m2t.export(gcf, 'figure');
```

On success, the call writes `figure.tex` and `figure.pdf`. Existing products are
not overwritten unless `'Overwrite', true` is requested.

Publication styling is explicit:

```matlab
result = m2t.export(gcf, 'figure', ...
    'Profile', 'publication', 'Width', 'single-column');
```

## Supported Areas

The validated core includes 2-D lines, markers, constant-style scatter, error
bars, legends, logarithmic and reversed axes, custom ticks, multiple/manual
axes, colorbars, scalar images/heatmaps, supported annotations, grouped vertical
bars, traditional vertical boxplots, Line3, and a narrow orthographic surface
and Patch3 scope. Figure sets, publication profiles, deterministic IR replay,
and explicit image-backend planning are also available.

Consult the [support matrix](../SUPPORT.md) before relying on advanced graphics.

## Known Limitations

Version 0.5.0 remains pre-1.0, so APIs and schemas may evolve. Unsupported or
non-general areas include per-point scatter semantics, `tiledlayout`/`nexttile`,
`yyaxis`, polar plots, arbitrary annotation and patch families, stacked or
horizontal/categorical bars, broad `boxchart` behavior, general 3-D scenes,
mesh/scatter3/contour3, perspective, lighting/material semantics, broad
transparency, and general downsampling.

## Validation

The portable release matrix covers 266 structured cases, examples 01–10,
architecture invariants, documentation and citation validation, Actionlint, and
six curated LuaLaTeX preview compilations. Hosted CI retains the required
`repository-policy`, `octave-tests`, and `tex-preview` jobs.

## MATLAB / Octave Boundary

Validated with MATLAB R2026a Update 4 on Windows. This does not imply support
for other MATLAB releases or platforms. GNU Octave 11.3 is exercised by hosted
Linux CI and local validation. Runtime representation differences are described
in [MATLAB and Octave validation differences](../MATLAB_OCTAVE_DIFFERENCES.md).

## Upstream Relationship

m2tikz-next retains the original matlab2tikz history, license, copyright
notices, and contributor attribution. The public modern APIs are `m2t.export`
and `m2t.exportSet`; the inherited `matlab2tikz(...)` API remains separate. See
[NOTICE.md](../../NOTICE.md) and [AUTHORS.md](../../AUTHORS.md).

Security reports should use GitHub Private Vulnerability Reporting rather than
a public issue.

## Upgrade / Compatibility Notes

This is the first public m2tikz-next release, so there is no earlier public
m2tikz-next release to upgrade from. The `m2t2.*` namespace, FigureIR, JSON, and
manifest schemas are internal/experimental and do not carry a pre-1.0
compatibility promise. Users should build integrations around `m2t.export` and
`m2t.exportSet` and review structured diagnostics after each export.
