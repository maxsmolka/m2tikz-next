# Scientific export workflow

> M3 development / next release. This API is not part of
> `v0.1.0-preview.1` and does not carry a pre-1.0 stability promise.

This public workflow is validated locally with MATLAB R2026a Update 4 on
Windows without MATLAB-specific API expectations. The claim is limited to that
release and environment; see
[MATLAB_VALIDATION_MATRIX.md](MATLAB_VALIDATION_MATRIX.md).

The public workflow turns a supported graphics figure into standalone PGFPlots
TeX and a validated PDF with one call:

```matlab
addpath('src');
x = linspace(0, 2*pi, 200);
plot(x, sin(x));
result = m2t.export(gcf, 'figures/sine');
```

## Stages

1. **Analysis** reads the figure once through `m2t2.reader.readFigure` and
   validates the normalized IR. No output is written during this stage.
2. **Planning** resolves the requested image representation from validated IR.
3. **Profile transform** applies the selected deterministic publication size
   and generic render configuration. The default `none` transform is inert.
4. **Export** renders standalone PGFPlots TeX from the transformed IR and writes
   `<outputBase>.tex`.
5. **Compile** discovers `lualatex` through `PATH`, runs it in a temporary build
   directory, captures its output, and copies the resulting PDF to
   `<outputBase>.pdf`.
6. **Validation** checks that the PDF exists, is nonempty, and starts with a PDF
   header.

There is no silent fallback to the inherited `matlab2tikz(...)` exporter.

## Result fields

`m2t.export` always returns a struct with stable M3.0 field names:

| Field | Meaning |
| --- | --- |
| `success` | Logical overall outcome. |
| `status` | `success`, `export_failed`, `compile_failed`, `validation_failed`, or `unsupported`. |
| `capability` | Analysis classification: `supported`, `unsupported`, or `invalid`. |
| `texPath` | Absolute standalone TeX path. |
| `pdfPath` | Absolute final PDF path. |
| `logPath` | Retained compilation log path on compiler failure; otherwise empty. |
| `backend` | `pgfplots` in M3.0. |
| `compiler` | `lualatex` in M3.0. |
| `profile` | Applied profile name, width, physical figure size, and size unit. |
| `render` | Requested/selected image backend, reason, policy, and generated assets. |
| `diagnostics` | Struct array described below. |
| `timings` | Seconds spent in `analysis`, `export`, `compile`, `validation`, and `total`. |

No performance guarantee is implied by the timing values.

## Diagnostics

Every diagnostic has four fields:

| Field | Values |
| --- | --- |
| `severity` | `info`, `warning`, or `error`. |
| `code` | Stable workflow code or the original precise `M2T2:*` identifier. |
| `message` | User-readable failure detail. |
| `stage` | `analysis`, `export`, `compile`, or `validation`. |

Unsupported reader content retains identifiers such as
`M2T2:E001:UnsupportedObject`. A missing compiler returns
`M2T:C001:CompilerNotFound`. A TeX failure retains a
`<outputBase>.compile.log` and includes the first meaningful TeX error in its
diagnostic instead of returning only an exit code.

Scalar `imagesc`-style matrices use the same result and diagnostic path. See
[IMAGE_PLOTS.md](IMAGE_PLOTS.md) for supported coordinates, color semantics,
non-finite behavior, structured image diagnostics, and measured size costs.
Dense matrices may explicitly select `hybrid` or opt into `auto`; the default is
`vector`. Hybrid assets and lifecycle are documented in
[IMAGE_BACKENDS.md](IMAGE_BACKENDS.md), and the planner policy is documented in
[BACKEND_PLANNER.md](BACKEND_PLANNER.md).

## Output and overwrite policy

`outputBase` is an extension-free relative or absolute path. Parent directories
are created when needed. Compiler intermediates stay in a temporary directory;
successful exports leave only the requested `.tex` and `.pdf` products.

The default is fail-safe: an existing `.tex`, `.pdf`, or `.compile.log` product
causes `export_failed` and is not modified. Deliberate replacement is explicit:

```matlab
result = m2t.export(gcf, 'figures/sine', 'Overwrite', true);
```

There are no interactive prompts. The process layer quotes file paths and
rejects unsafe process argument forms; renderer code never constructs or runs a
shell command.

## Publication profile

Profile application is opt-in and remains experimental:

```matlab
result = m2t.export(gcf, 'figures/sine', ...
    'Profile', 'publication', 'Width', 'double-column');
```

Omit `Width` for the 85 mm single-column default, or select the 170 mm
double-column preset. `Width` is invalid with `Profile='none'`. Unknown profiles
and invalid widths return structured analysis diagnostics. The complete values
and preservation policy are documented in [PROFILES.md](PROFILES.md).

## Compiler requirements

M3.0 supports LuaLaTeX only. `lualatex` must be discoverable through `PATH`, and
the TeX installation must provide TikZ, PGFPlots 1.18 compatibility, and the
`standalone` class. On Ubuntu these are covered by `texlive-luatex`,
`texlive-pictures`, and `texlive-latex-extra`.

## Current limitations

- The document backend remains PGFPlots; `ImageBackend` plans only scalar
  image-layer representation and never rasterizes a complete figure.
- The pre-1.0 profile API currently provides only `none` and `publication`;
  numeric custom widths are deferred.
- Unsupported modern-reader content remains explicit and never falls back to
  the legacy exporter.
- RGB/alpha images, direct-indexed or nonlinear image color mapping,
  `tiledlayout`, `yyaxis`, polar plots, arbitrary annotations, migrated 3-D
  rendering, and unsupported per-point scatter styling remain out of scope.
- Visual/raster comparison remains a development validation concern and is not
  part of the normal user call.

The architectural rationale is recorded in
[ADR-0007](adr/ADR-0007-scientific-export-workflow.md).
Publication-profile layering is recorded in
[ADR-0008](adr/ADR-0008-publication-profiles.md).

## Figure sets

`m2t.exportSet` builds explicitly supplied figures through repeated calls to
this same workflow. It adds set preflight, deterministic configuration
inheritance, aggregate results, continue-on-error behavior, and manifest
schema 1; it does not duplicate analysis, rendering, compilation, or PDF
validation:

```matlab
entries = struct('figure', {firstFigure, secondFigure}, ...
                 'name', {'overview', 'comparison'});
result = m2t.exportSet(entries, 'figures', ...
    'Profile', 'publication', 'ContinueOnError', true);
```

See [FIGURE_SETS.md](FIGURE_SETS.md) for preflight rules, entry overrides,
aggregate statuses, output collision behavior, and manifest content. The
architectural decision is recorded in
[ADR-0009](adr/ADR-0009-figure-set-workflow.md).
The scalar image representation is recorded in
[ADR-0010](adr/ADR-0010-image-matrix-representation.md).
The explicit hybrid backend is recorded in
[ADR-0011](adr/ADR-0011-hybrid-image-backend.md).
The deterministic planner is recorded in
[ADR-0012](adr/ADR-0012-image-backend-planner.md).
