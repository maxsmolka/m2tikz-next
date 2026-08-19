# m2tikz-next

> Public preview candidate - MATLAB R2026a Update 4 validated on Windows

A modern, validated scientific figure export pipeline derived from matlab2tikz.
m2tikz-next converts supported GNU Octave and MATLAB figures into deterministic,
standalone PGFPlots documents while preserving the original repository history
and legacy exporter.

## Why m2tikz-next?

The modernization separates runtime-specific graphics inspection from output
generation. A reader normalizes a figure into a versioned intermediate
representation (IR), and a handle-free renderer serializes that IR with explicit
diagnostics. This creates a foundation for deterministic export, scientific-data
preservation, multiple-axes layout, compilation checks, and reproducible
validation.

## Current status

The repository is preparing its first public preview. The modern path is
validated with GNU Octave and LuaLaTeX on the environment listed below; it is not
a full replacement for every inherited matlab2tikz feature.

Hosted CI is provided through GitHub Actions.

The modern pipeline is validated locally with MATLAB R2026a Update 4 on Windows.
This does not imply support for every MATLAB release. See [support status](docs/SUPPORT.md)
and the [MATLAB validation matrix](docs/MATLAB_VALIDATION_MATRIX.md) for the
exact capability and environment boundaries.

## Features

- versioned, normalized figure IR with JSON migration and replay;
- runtime-isolated readers and graphics-handle-free rendering;
- deterministic PGFPlots serialization and explicit diagnostics;
- line, constant-style scatter, and symmetric/asymmetric errorbar series;
- grouped vertical bar series with numeric categories and constant styles;
- vertical legacy `boxplot(...)` series in the validated filled/traditional scope;
- scalar 2-D image/heatmap series with exact matrix data and explicit colormaps;
- explicit hybrid PNG layers for dense heatmaps, with vector axes and text;
- opt-in deterministic backend planning with structured decision metadata;
- multiple axes, subplot-style and manual layouts, and overlays;
- axes-owned colorbars plus figure-level elements in IR/renderer tests;
- axes-owned 2-D user text plus figure-owned arrow/double-arrow annotations;
- semantic, compilation, visual, and performance validation infrastructure.

## Quick start

> **M3 development / next release:** the `m2t.*` workflow below is under
> development on the M3 branch and is not part of `v0.1.0-preview.1`.

With GNU Octave, LuaLaTeX, and PGFPlots on `PATH`:

```matlab
addpath('src');

x = linspace(0, 2*pi, 200);
plot(x, sin(x));
xlabel('x');
ylabel('sin(x)');

result = m2t.export(gcf, 'figures/example');
```

One call analyzes the figure through the modern reader, writes standalone TeX,
runs LuaLaTeX, validates the PDF, and returns machine-readable status and
diagnostics. It creates `figures/example.tex` and `figures/example.pdf`.
Existing export products are preserved by default; use the deliberate
`'Overwrite', true` option to replace them.

Publication styling is opt-in. The calibrated publication profile applies
normative physical sizing and TeX-native typography while preserving the
normalized scientific content:

```matlab
result = m2t.export(gcf, 'figures/example', ...
    'Profile', 'publication', 'Width', 'single-column');
```

See the [publication profile](docs/PUBLICATION_PROFILE.md) for
the normative 85 mm and 170 mm policy and [publication profiles](docs/PROFILES.md)
for API diagnostics and pre-1.0 limitations.

Rebuild an explicit publication figure set through the same single-figure
pipeline:

```matlab
entries(1) = struct('figure', figureOne, 'name', 'overview');
entries(2) = struct('figure', figureTwo, 'name', 'error-analysis');
result = m2t.exportSet(entries, 'build/figures', ...
    'Profile', 'publication', 'Overwrite', true);
```

The workflow preflights safe names, aggregates every single-export result, and
writes a deterministic manifest. See [figure sets](docs/FIGURE_SETS.md).

Dense scalar matrices can opt into a compact lossless data layer while keeping
the scientific presentation vector-based:

```matlab
result = m2t.export(gcf, 'figures/dense-field', ...
    'ImageBackend', 'hybrid', 'Profile', 'publication');
```

The default remains `ImageBackend='vector'`. Callers may explicitly opt into
the deterministic `ImageBackend='auto'` policy; see
[backend planning](docs/BACKEND_PLANNER.md) and
[image rendering backends](docs/IMAGE_BACKENDS.md).

The lower-level experimental path remains available when compilation is not
wanted:

```matlab
m2t2.export(gcf, 'figure.tex', true);
```

See [the scientific export workflow](docs/WORKFLOW.md) for result fields,
diagnostics, compiler requirements, and current limitations. Image-specific
scope and performance evidence are in [image and matrix plots](docs/IMAGE_PLOTS.md).

## Example

Ten regenerable examples cover line, scatter, errorbar, multiple-axes,
colorbar, default-versus-publication profiles, a four-figure publication set,
vector/hybrid scientific heatmaps, and opt-in automatic selection. See
[examples/README.md](examples/README.md) for commands. The repository does not
track their generated TeX or PDF output.

## Supported environment

The recorded preview baselines are GNU Octave 11.3 and MATLAB R2026a Update 4
on Windows, with TeX Live 2026, PGFPlots 1.18.x, and LuaLaTeX. Hosted GNU Octave
11.3 Linux CI remains mandatory. The MATLAB statement is release-specific and
does not validate older or newer releases.

## Experimental API

`m2t.*` is the user-facing workflow namespace under M3 development. It is not a
pre-1.0 stability promise. `m2t2.export(...)`, all other `m2t2.*` APIs, and the
IR/JSON schemas remain experimental internals. The internal packages are not
being mechanically renamed.

## Legacy matlab2tikz API

The inherited `matlab2tikz(...)` API remains available and retains its historical
behavior. It is not silently redirected to `m2t2.export(...)`; the modern and
legacy paths are separate.

## Known limitations

The modern path does not yet cover RGB/alpha images, non-scaled image mapping,
`tiledlayout`, `yyaxis`, polar plots, arbitrary annotation shapes, 3-D
annotations, generic 3-D scenes, or all per-point scatter styling. The modern
path supports the validated narrow slice of orthographic Cartesian scalar
surfaces with interpolated coloring, Plot3 decoration, pattern-owned triangular
Fill3 decoration, and the existing semantic colorbar path. Mesh, scatter3,
contour3, lighting/materials, transparency, perspective, and arbitrary 3-D
patches remain unsupported. The
supported annotation slice is limited to axes-data user text and
figure-normalized arrow/double-arrow objects. Stacked/horizontal bars,
histogram objects, per-bar mapped colors, and generic patch compounds remain
unsupported. Horizontal/notched
boxplots, `boxchart`, violin/swarm plots, and arbitrary statistical compounds
remain unsupported. Shared figure elements have renderer/IR coverage
but incomplete runtime-reader coverage. Consult
[docs/SUPPORT.md](docs/SUPPORT.md) before relying on a feature.

## Installation

The preview uses a source checkout rather than a package manager:

```console
git clone https://github.com/maxsmolka/m2tikz-next.git
cd m2tikz-next
octave-cli --quiet --eval "addpath('src'); disp(which('m2t2.export'))"
```

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for the Windows-first validated
setup and tool verification.

## Validation

Run the public-preview validation from PowerShell:

```powershell
./test/runPublicPreviewValidation.ps1
```

The script discovers its environment, runs reader and renderer suites, generates
and compiles the curated examples, checks the renderer invariant, and performs
publication-path checks. Generated output stays below ignored `.audit/` paths.

## Roadmap

M3 introduces the scientific export workflow, publication profiles, figure
sets, scalar heatmaps, annotations, grouped bars, semantic boxplots, a narrow
3-D surface contract, and opt-in deterministic image-backend planning.
`tiledlayout`, `yyaxis`, polar plots, and generic 3-D scenes remain outside the
current scope. Preview readiness does not imply 1.0 compatibility.

## Origin and attribution

m2tikz-next is independently developed from the original
[matlab2tikz](https://github.com/matlab2tikz/matlab2tikz) project and preserves
its Git history, license, copyright notices, and contributor record. It is not an
official matlab2tikz 2.0 release and is not presented as endorsed by the original
maintainers. See [NOTICE.md](NOTICE.md) and [AUTHORS.md](AUTHORS.md).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing reader/IR/renderer
boundaries or adding fixtures. MATLAB implications must be documented even when
only the validated Octave path can be executed.

## Security

Do not disclose suspected vulnerabilities or credentials in a public issue. The
repository owner must enable GitHub Private Vulnerability Reporting before the
public announcement; see [SECURITY.md](SECURITY.md).

## License

The inherited license text in [LICENSE.md](LICENSE.md) remains authoritative.
Attribution and third-party review decisions are recorded in [NOTICE.md](NOTICE.md)
and [docs/release/LICENSE_AUDIT.md](docs/release/LICENSE_AUDIT.md).
