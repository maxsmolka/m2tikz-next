# Public API freeze candidate

M7.0 designates the existing `m2t.export` and `m2t.exportSet` surface as the
**1.0 API-freeze candidate**. The latest released version remains 0.5.0.
There is no breaking cleanup or new alias in this milestone. Breaking changes
after this candidate require exceptional justification, an ADR, migration notes
and one canonical replacement; additive fields/options must preserve defaults.
Consumers should accept additional result fields and handle unfamiliar failure
codes conservatively. This is not a claim of complete graphics coverage.

The [0.8.0 feature-freeze policy](release/FEATURE_FREEZE_0_8_0.md) further
restricts planned work before 1.0. Preserving compatibility is necessary but
does not by itself authorize unrelated additive options or graphics families.

`m2t2.*`, `m2t.internal.*`, `m2t.profile.*`, `m2t.planning.*`, renderer options
and JSON helpers are implementation interfaces, not additional public entry
points. The inherited `matlab2tikz(...)` API is separate; no fallback uses it.

## Calls and options

```matlab
result = m2t.export(figureHandle, outputBase, Name, Value, ...);
result = m2t.exportSet(entries, outputDirectory, Name, Value, ...);
```

Supply a live supported figure explicitly, never implicit figure discovery.
Paths accept a character row or scalar string. Option names and enumerated
profile/width/backend values are case-insensitive, not whitespace-trimmed.
Options are name-value pairs; unknown names and invalid types fail. Repeated
option names use the last value. Logical options require logical scalars, not
numeric zero/one. Required positional arguments must be supplied; invalid call
arity and runtime termination are outside the structured operational contract.

| Option | Default | Accepted values and meaning |
| --- | --- | --- |
| `Overwrite` | `false` | Logical scalar; explicit replacement of owned products only. |
| `Profile` | `'none'` | `'none'` or `'publication'`; no custom profile struct. |
| `Width` | `[]` (omitted) | Empty means source size for none, or single-column for publication. Nonempty `'single-column'` / `'double-column'` requires publication. Numeric widths and `'source'` input are not accepted. |
| `ImageBackend` | `'vector'` | `'vector'`, `'hybrid'`, `'auto'`; image layers only. |
| `ContinueOnError` | `true` | Set only, logical scalar; false records remaining entries as skipped after first failed entry. |

Publication widths are 85/170 mm. Geometry, typography, preserved data and
explicit limitations are in [PROFILES.md](PROFILES.md). Profiles do not mutate
source figures. Vector is not silently changed on resource failure. Explicit
hybrid preserves pixel dimensions with 8-bit PNG channels; auto uses policy
`default-v1`: nonopaque alpha, then RGB require hybrid, otherwise the largest
visible scalar image selects hybrid above 4096 cells. No image selects vector.
Explicit requests win subject to capability checks: forcing rich images to
vector fails, it does not discard color/alpha. See [BACKEND_PLANNER.md](BACKEND_PLANNER.md)
and [IMAGE_BACKENDS.md](IMAGE_BACKENDS.md). No public threshold, compiler choice,
TeX-only switch, arbitrary renderer options or data-reduction option exists.

## Single-export result

For correctly shaped calls, operational failures return a scalar struct rather
than a successful-looking incomplete figure. Check `success`, not path existence.
Calling without an output prints a concise summary and performs the same work.

| Field | Contract |
| --- | --- |
| `success` | Logical, true only after supported analysis, output, compilation and PDF-header/nonempty validation. |
| `status` | `success`, `unsupported`, `export_failed`, `compile_failed`, `validation_failed`; set entries may also be `skipped`. |
| `capability` | `supported`, `unsupported`, `invalid`; analysis classification, not overall success. |
| `texPath`, `pdfPath`, `logPath` | Absolute local workflow paths once resolved; not proof that a product exists. Before compilation, logPath can name the intended failure log. Completed compiler outcomes clear it unless a log was retained. Early invalid arguments can leave paths empty. |
| `backend`, `compiler` | `pgfplots`, `lualatex`. |
| `profile` | `name`, `width`, `widthMillimeters`, `figureSize`, `figureSizeUnit` (`pt`); applied metadata, or initial none/source defaults if application was not reached. |
| `render` | `requestedImageBackend`, `effectiveImageBackend`, `imageBackend`, `assets` (cell array of absolute generated PNG paths). |
| `diagnostics` | Ordered struct array of `severity`, `code`, `message`, `stage`. |
| `timings` | `analysis`, `export`, `compile`, `validation`, `total` seconds. Observations, not performance guarantees or additive accounting promises. |

`render.imageBackend` contains `requested`, `selected`, `reason`, `policy`,
`imageLayerCount`, `maxImageCells`. Policy fields are `name`, `version`, `id`,
`maxVectorCells`. Selection reasons are `explicit_vector`, `explicit_hybrid`,
`no_image_layer`, `small_scalar_image`, `dense_scalar_image`,
`truecolor_requires_hybrid`, `alpha_requires_hybrid`, or `not_planned`.
When `reason='not_planned'`, do not interpret initial/empty selected or effective
values as a completed decision. Initial values may survive argument failure.
The effective legacy field can still equal the request when planning failed.
Future policy changes must use a new policy identity and documented behavior.

## Diagnostics and failure semantics

Stable automation keys are full `code` identifiers, severity, stage and status;
not a numeric substring alone, exact prose or stack traces. Reader identifiers
are preserved at the public boundary. Expected workflow stages are `analysis`,
`planning`, `export`, `compile`, `validation`, and set-level `set`.
The same invalid input yields deterministic first-failure order; the result is
not an exhaustive collection of every unsupported property. Diagnostics may
contain caller paths and compiler text; redact before sharing logs.

Analysis rejects unsupported objects with `status='unsupported'`; invalid input
or profile/planning/render/output failure uses `export_failed`. For example,
forced-vector RGB fails in planning with `M2T2:E053:UnsupportedVectorRichImage`
and can still have `capability='supported'`. Compiler absence is
`M2T:C001:CompilerNotFound`, compiler error `M2T:C003:CompilationFailed`.
Both use `compile_failed`; PDF validation is a separate status and is not a
visual-fidelity comparison. Detailed identifiers are in
[design/DIAGNOSTICS.md](design/DIAGNOSTICS.md).

## Output paths, overwrite and lifecycle

`outputBase` is a filename base: extensions are appended, never stripped
(`plot.v1` becomes `plot.v1.tex`; `plot.tex` becomes `plot.tex.tex`). Relative
paths resolve against the call's working directory; explicit absolute paths
and parent traversal are caller-authorized destinations, not a sandbox.
Spaces/dots/underscores are supported subject to OS restrictions. Control
characters and unsafe TeX filename characters are rejected; Windows additionally
rejects reserved device names and unsafe process characters. Linked parent
directories may be intentional; linked final products are rejected.

Owned products are `<base>.tex`, `<base>.pdf`, `<base>.compile.log`, and the
flat `<base>-assets/` directory containing generated `image-0001.png`, etc.
Without overwrite, any existing owned product causes failure without replacing
it. With overwrite, all products are preflighted before replacement; old PDF,
failure log and recognized generated assets are removed, then new TeX/assets
are written. Foreign/nested asset content and redirected products fail safely.
This is **not an atomic transaction or rollback promise**: write/compiler
failure can leave new TeX/assets and no PDF; an earlier file may remain if a
write fails. Analysis/planning failure occurs before output preparation.
Callers must serialize concurrent writes to the same base/set directory.

LuaLaTeX must be on PATH. Compilation uses temporary staging, no shell escape,
and retains a failure log when possible. MATLAB path inspection needs the JVM.
The compiler is not sandboxed: export trusted content only; see
[SECURITY.md](../SECURITY.md). Source figures are not closed or restyled.
Calls are synchronous without a built-in process timeout. Generated text is
explicit UTF-8 without BOM; PNG write/encoding failures use the existing
`M2T2:E_PNG_WRITE_FAILED` diagnostic rather than vendor-specific encoder codes.
See [the environment contract](ENVIRONMENT_CONTRACT.md) for paths, locale,
temporary staging and the distinction between native and bridged TeX evidence.

## Figure sets and manifest schema 1

`entries` is a nonempty struct vector with required case-sensitive `figure`
and `name` fields, and only optional `profile`, `width`, `overwrite`,
`imageBackend`. Empty overrides inherit. Precedence is nonempty entry override,
then set option, then single-export default, independently per property.
Thus changing an entry profile to none while inheriting a nonempty publication
width is invalid unless the overall effective combination is resolved.
Names match `[A-Za-z0-9][A-Za-z0-9_-]*`, unique case-insensitively; no nested
names, spaces, dots or traversal. All configuration/product collisions are
preflighted before any entry exports; figure capability is checked per entry.

Set results have `success`, `status`, `outputDirectory`, `manifestPath`,
`entries`, `diagnostics`, `summary`, `timings`. Status is `invalid_set` on
preflight failure, otherwise `success`, `partial_failure` or `failed`.
Set-level diagnostics are separate from `entries(k).result.diagnostics`.
Each entry has `name`, the complete single `result`, and `effective` fields
`profile`, `width`, `overwrite`, `imageBackend`, `requestedImageBackend`,
`selectedImageBackend`, `backendReason`, `backendPolicy`.
Summary fields `total`, `succeeded`, `failed`, `unsupported`, `skipped` count
entry outcomes, not manifest errors. Timings are `preflight`, `export`, `total`.

`ContinueOnError=false` records later entries as skipped with
`M2T:SET_SKIPPED_AFTER_FAILURE`; successful earlier products remain.
After a preflight-valid run, the workflow attempts `m2t-manifest.json`, even
when all entries failed. A manifest-write failure yields `partial_failure` if
any entry succeeded, else `failed`, with `M2T:SET_MANIFEST_WRITE_FAILED`.
Consequently partial_failure can coexist with all entries successful.
The set-level Overwrite controls the manifest, not an entry override.

Manifest schema 1 is independent of FigureIR. Root fields are `schemaVersion`,
`generatedBy`, `defaults`, `figures`; defaults record profile, resolved width,
overwrite, imageBackend, continueOnError. Ordered figure records contain name,
status, relative tex/pdf paths, profile, width, imageBackend, requested/selected
backend, backendReason, backendPolicy and relative assets. Failed/skipped
records' paths need not exist. No handles, IR, timings, diagnostics messages,
timestamps or absolute output roots are persisted. Accept additive fields;
incompatible meaning/type/removal needs a manifest schema bump and migration
policy. Same implementation/options/outcomes/order produce identical manifest
bytes, not necessarily identical PDFs. See [FIGURE_SETS.md](FIGURE_SETS.md)
and [DETERMINISM.md](DETERMINISM.md).
