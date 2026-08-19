# m2tikz-next

> Working release target: 0.5.0 — usable pre-1.0 scientific-export preview/beta

m2tikz-next is a modern, validated scientific figure export pipeline derived
from [matlab2tikz](https://github.com/matlab2tikz/matlab2tikz). It converts
supported MATLAB and GNU Octave figures into deterministic standalone PGFPlots
documents, with explicit diagnostics when a figure cannot be represented
faithfully. It preserves upstream history and attribution but is an independent
project, not an official matlab2tikz release or successor.

The current validation boundary is GNU Octave 11.3 in hosted Linux CI and
MATLAB R2026a Update 4 on Windows. TeX output is compiled with LuaLaTeX using
TeX Live 2026 and PGFPlots 1.18.x. See [Installation](docs/INSTALLATION.md) for
the complete setup.

```matlab
addpath('src');

x = linspace(0, 2*pi, 200);
y = sin(x);
figure;
plot(x, y);

result = m2t.export(gcf, 'figure');
```

On success this writes `figure.tex` and `figure.pdf`. Existing products are
preserved unless `'Overwrite', true` is requested.

## Installation

Clone the source checkout and add its `src` directory to the MATLAB or Octave
path:

```console
git clone https://github.com/maxsmolka/m2tikz-next.git
cd m2tikz-next
```

```matlab
addpath('src');
assert(~isempty(which('m2t.export')));
```

The export workflow also requires LuaLaTeX, TikZ, and PGFPlots. Full runtime,
TeX, platform, and verification instructions are in
[docs/INSTALLATION.md](docs/INSTALLATION.md).

## Public workflow

`m2t.export` is the primary single-figure API. It analyzes the source figure,
normalizes supported semantics into a versioned intermediate representation
(IR), writes standalone TeX, compiles with LuaLaTeX, validates the PDF, and
returns structured status, paths, timings, and diagnostics. See
[Workflow](docs/WORKFLOW.md).

Publication styling is opt-in:

```matlab
result = m2t.export(gcf, 'figures/result', ...
    'Profile', 'publication', 'Width', 'single-column');
```

The publication profile provides deterministic physical sizing and TeX-native
typography without changing normalized scientific data. See
[Profiles](docs/PROFILES.md) and the calibrated
[publication profile](docs/PUBLICATION_PROFILE.md).

`m2t.exportSet` rebuilds an explicit collection through the same single-figure
pipeline and writes a deterministic manifest:

```matlab
entries(1) = struct('figure', figureOne, 'name', 'overview');
entries(2) = struct('figure', figureTwo, 'name', 'comparison');
result = m2t.exportSet(entries, 'build/figures', ...
    'Profile', 'publication', 'Overwrite', true);
```

See [Figure sets](docs/FIGURE_SETS.md) for entry rules, failure aggregation,
and output layout.

## Supported scientific figures

The validated modern path covers 2-D lines and Line3, constant-style scatter,
error bars, legends, logarithmic/reversed axes, custom ticks, multiple and
manually positioned axes, colorbars, scalar images/heatmaps, free 2-D text,
arrows, grouped vertical bars, narrow traditional vertical boxplots, and a
narrow orthographic 3-D surface/Patch3 scope.

Support is intentionally capability-based and conservative. Some families are
supported only within explicit limits, and unsupported objects fail with
structured diagnostics instead of being silently omitted. The authoritative
classification is [docs/SUPPORT.md](docs/SUPPORT.md); runtime differences are
documented in
[MATLAB and Octave differences](docs/MATLAB_OCTAVE_DIFFERENCES.md).

## Image and hybrid backends

Scalar image data can use the default vector backend or an explicit hybrid PNG
layer while keeping axes, labels, and other scientific presentation vector
based. The deterministic `auto` planner is opt-in:

```matlab
result = m2t.export(gcf, 'figures/dense-field', ...
    'ImageBackend', 'auto', 'Profile', 'publication');
```

See [Image backends](docs/IMAGE_BACKENDS.md) and
[backend planning](docs/BACKEND_PLANNER.md). No backend performs general
downsampling or silently changes source data.

## Design principles

The pipeline isolates runtime-specific graphics inspection in readers, stores
normalized semantics in a versioned IR, and renders without graphics handles.
For scientific output, a plausible but incomplete figure is a product risk:
unsupported content should produce explicit structured diagnostics. Identical
supported inputs and configuration are intended to yield deterministic export
plans and text.

## Current limitations

The 0.5.0 target is pre-1.0: APIs and schemas may still change. Unsupported or
non-general areas include per-point scatter semantics, `tiledlayout`/`nexttile`,
`yyaxis`, polar plots, arbitrary annotations and patch semantics, stacked or
horizontal/categorical bars, broad modern `boxchart` behavior, general 3-D
scenes, mesh/scatter3/contour3, perspective, lighting/material semantics, broad
transparency, and general downsampling. MATLAB validation is limited to the
exact release and platform stated above; other MATLAB releases are not implied.

## Examples and validation

[Examples 01–10](examples/README.md) demonstrate line, scatter, error bars,
multiple axes, colorbars, publication profiles and figure sets, and vector,
hybrid, and automatic image backends using generic synthetic data.

Run the portable repository gate from PowerShell:

```powershell
./test/runPublicPreviewValidation.ps1
```

Generated validation products stay below ignored `.audit/` directories.

## Documentation

- [Installation](docs/INSTALLATION.md)
- [Support matrix](docs/SUPPORT.md)
- [Profiles](docs/PROFILES.md)
- [Figure sets](docs/FIGURE_SETS.md)
- [Image backends](docs/IMAGE_BACKENDS.md)
- [Workflow and diagnostics](docs/WORKFLOW.md)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)

The public end-user APIs are `m2t.export` and `m2t.exportSet`.
`m2t2.*`, the IR, and serialization helpers are internal/experimental
implementation interfaces and are not recommended as end-user entry points.
The inherited `matlab2tikz(...)` API remains separate and keeps its historical
behavior.

## Project status, attribution, and license

Version 0.5.0 is a coherent first public preview/beta target, not a promise of
1.0 stability or complete MATLAB graphics coverage. Contributions should
preserve explicit support boundaries and deterministic behavior; read
[CONTRIBUTING.md](CONTRIBUTING.md) before proposing changes.

m2tikz-next retains the original matlab2tikz Git history, license, copyright
notices, and contributor record. See [NOTICE.md](NOTICE.md) and
[AUTHORS.md](AUTHORS.md). The inherited BSD-2-Clause license in
[LICENSE.md](LICENSE.md) remains authoritative.
