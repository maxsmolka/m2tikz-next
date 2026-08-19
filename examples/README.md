# Examples

These examples generate standalone TeX below the ignored
`.audit/public-preview/examples/` directory by default. Run them from the
repository root with GNU Octave:

```console
octave-cli --quiet --eval "addpath('examples/01-line'); example_line()"
octave-cli --quiet --eval "addpath('examples/02-scatter'); example_scatter()"
octave-cli --quiet --eval "addpath('examples/03-errorbar'); example_errorbar()"
octave-cli --quiet --eval "addpath('examples/04-multiple-axes'); example_multiple_axes()"
octave-cli --quiet --eval "addpath('examples/05-colorbar'); example_colorbar()"
octave-cli --quiet --eval "addpath('examples/06-publication-profile'); example_publication_profile()"
octave-cli --quiet --eval "addpath('examples/07-publication-figure-set'); example_publication_figure_set()"
octave-cli --quiet --eval "addpath('examples/08-scientific-heatmap'); example_scientific_heatmap()"
octave-cli --quiet --eval "addpath('examples/09-hybrid-heatmap'); example_hybrid_heatmap()"
octave-cli --quiet --eval "addpath('examples/10-auto-image-backend'); example_auto_image_backend()"
```

Compile one result, for example:

```console
lualatex .audit/public-preview/examples/01-line.tex
```

`test/runPublicPreviewValidation.ps1` regenerates and compiles the five
low-level preview examples in an isolated output directory. The M3.1 profile
suite runs the sixth example's public workflow and validates its default,
single-column 85 mm, and double-column 170 mm outputs. The seventh example rebuilds four publication figures
through one `m2t.exportSet` call. Generated TeX and PDFs are not source files.
The eighth example exports a scalar Gaussian-residual heatmap through the
publication profile with explicit coordinates, color limits, colormap, and
colorbar.
The ninth example exports the same 100x100 field explicitly through vector and
hybrid backends so their output-size and rebuild-cost tradeoff is visible.
The tenth example opts a 25x25 and 100x100 field into `auto`, then reports the
vector/small and hybrid/dense decisions returned by policy `default-v1`.

The `m2t2.*` API and IR schema remain experimental. The modern pipeline is
validated with MATLAB R2026a Update 4 on Windows; that release-specific result
does not imply compatibility with all MATLAB versions.
