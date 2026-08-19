# Figure-set workflow

> `m2t.exportSet` and manifest schema 1 are experimental and carry no pre-1.0
> stability promise.

Publications commonly rebuild several related figures with one consistent
profile. `m2t.exportSet` accepts only explicitly supplied figure handles,
preflights the complete specification, delegates every entry to `m2t.export`,
and returns aggregate results plus a deterministic manifest.

## API and entry format

Entries are a MATLAB/Octave-friendly struct array with required lower-case
fields `figure` and `name`:

```matlab
entries(1).figure = overviewFigure;
entries(1).name = 'overview';

entries(2).figure = architectureFigure;
entries(2).name = 'architecture';
entries(2).width = 'double-column';

result = m2t.exportSet(entries, 'build/figures', ...
    'Profile', 'publication', ...
    'Width', 'single-column', ...
    'ImageBackend', 'hybrid', ...
    'Overwrite', true);
```

The optional entry fields are deliberately limited to the existing
single-export concepts: `profile`, `width`, `overwrite`, and `imageBackend`. Empty optional
fields inherit. No renderer options or internal IR values are accepted.

Configuration precedence is deterministic and property-specific:

```text
nonempty entry override > exportSet default > m2t.export default
```

The effective profile, width, overwrite value, and image backend are returned
in `result.entries(k).effective`. Profile and width combinations are resolved by
the same profile layer used by `m2t.export`. Auto requests additionally expose
requested/selected backend, stable reason, and policy ID; planning remains in
the delegated single-figure workflow.

## Set options

`Profile`, `Width`, `Overwrite`, and `ImageBackend` have the same defaults and
semantics as `m2t.export`: `none`, no width, `false`, and `vector`. The
publication profile supports `single-column` and `double-column` as documented
in [PROFILES.md](PROFILES.md).

`ContinueOnError` is set-specific and defaults to `true`. With the default, an
unsupported or failed entry does not hide later results. With `false`, the
first non-successful single export stops processing and every remaining entry
receives status `skipped` plus diagnostic
`M2T:SET_SKIPPED_AFTER_FAILURE` at stage `set`.

## Preflight and safe naming

Before the first figure is analyzed or any product is written, preflight
validates:

- a nonempty struct-vector entry set and required fields;
- the restricted optional-field vocabulary;
- set options and effective per-entry profile configuration;
- the output-directory value;
- safe, nonempty, case-insensitively unique names;
- collisions when the effective overwrite policy is false.

M3.2 names are filename stems only and must match
`[A-Za-z0-9][A-Za-z0-9_-]*`. Slashes, dots, whitespace, nested names, absolute
names, and traversal such as `../figure` are rejected. Consequently an entry
cannot escape the requested directory. Output directories themselves may be
relative or absolute and may contain spaces.

## Output layout and overwrite behavior

For output directory `figures` and entry `overview`, the workflow produces:

```text
figures/
  overview.tex
  overview.pdf
  m2t-manifest.json
```

An existing required product causes `invalid_set` during preflight when its
effective overwrite value is false. With overwrite enabled, each entry uses the
existing `m2t.export` replacement policy. The workflow is intentionally not a
whole-directory filesystem transaction: successful earlier figures remain if
a later figure fails. It never closes, destroys, or styles caller-owned figure
handles.

## Aggregate result

The returned struct contains:

| Field | Meaning |
| --- | --- |
| `success` | True only when all entries and the manifest succeed. |
| `status` | `success`, `partial_failure`, `failed`, or `invalid_set`. |
| `outputDirectory` | Absolute resolved figure-set directory. |
| `manifestPath` | Absolute manifest path for local workflow use. |
| `entries` | Name, effective configuration, and unchanged single `ExportResult`. |
| `diagnostics` | Set-level diagnostics only. |
| `summary` | `total`, `succeeded`, `failed`, `unsupported`, and `skipped`. |
| `timings` | Non-guaranteed `preflight`, entry-export, and total seconds. |

Individual diagnostics retain their original `m2t.export` identifiers. Set
validation uses stable identifiers including `M2T:SET_INVALID_ENTRY`,
`M2T:SET_DUPLICATE_NAME`, `M2T:SET_INVALID_NAME`,
`M2T:SET_INVALID_OUTPUT`, and `M2T:SET_OUTPUT_EXISTS`.

`partial_failure` means at least one entry succeeded and at least one did not.
`failed` means no entry succeeded. `invalid_set` means preflight prevented the
build from starting.

## Deterministic manifest

After every preflight-valid completed build, `m2t-manifest.json` records:

```json
{
  "schemaVersion": 1,
  "generatedBy": "m2tikz-next m2t.exportSet",
  "defaults": {
    "profile": "publication",
    "width": "single-column",
    "overwrite": true,
    "imageBackend": "auto",
    "continueOnError": true
  },
  "figures": [
    {
      "name": "overview",
      "status": "success",
      "tex": "overview.tex",
      "pdf": "overview.pdf",
      "profile": "publication",
      "width": "single-column",
      "imageBackend": "hybrid",
      "requestedImageBackend": "auto",
      "selectedImageBackend": "hybrid",
      "backendReason": "dense_scalar_image",
      "backendPolicy": "default-v1",
      "assets": ["overview-assets/image-0001.png"]
    }
  ]
}
```

Paths are relative to the set directory. Runtime handles, FigureIR, temporary
compiler directories, timestamps, random identifiers, timings, and absolute
machine paths are excluded. Identical build inputs therefore produce
byte-identical manifests. Manifest schema 1 is independent of FigureIR v2 and
may evolve before 1.0.

## Reproducible publication example

`examples/07-publication-figure-set/example_publication_figure_set.m` creates
analytic waves, uncertainty, samples, and multi-panel plots, then rebuilds
them with one call. Run from the repository root:

```matlab
addpath('examples/07-publication-figure-set');
result = example_publication_figure_set();
```

The script uses generic synthetic data, single-column defaults, a double-column
multi-panel override, and `Overwrite=true`, so it can be rerun reproducibly.

Scalar matrix plots remain ordinary entries with no image-specific set API.
Manifest schema 1 adds backward-compatible `imageBackend` and relative `assets`
fields plus requested/selected backend, reason, and policy metadata. Their
semantics and lifecycle are documented in [IMAGE_BACKENDS.md](IMAGE_BACKENDS.md)
and [BACKEND_PLANNER.md](BACKEND_PLANNER.md).

## Limitations

M3.2 does not discover open figures, derive names from figure numbers, accept
nested output names, provide whole-set atomic replacement, or add a project
configuration format. It adds no renderer, compiler, profile, plot type,
backend, layout feature, data reduction, or legacy fallback. Each entry remains
subject to the existing modern reader's explicit support policy.
