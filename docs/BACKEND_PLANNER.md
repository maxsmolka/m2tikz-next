# Deterministic image-backend planner

`ImageBackend='auto'` opts a supported image figure into a small,
deterministic representation decision. Existing calls remain vector by default,
and explicit `vector` or `hybrid` requests always win:

```matlab
result = m2t.export(gcf, 'figures/field', 'ImageBackend', 'auto');
decision = result.render.imageBackend;
```

The decision reports `requested`, `selected`, `reason`, `policy`, visible
`imageLayerCount`, and `maxImageCells`. The legacy additive fields
`requestedImageBackend` and `effectiveImageBackend` remain available.

## Default policy

Policy `default-v1` uses only the largest visible scalar image layer:

```text
maximum cells <= 4096 -> vector
maximum cells >  4096 -> hybrid
```

The 4096-cell limit is the exact 64x64 boundary. M3.4 measurements show that a
25x25 vector image remains inexpensive, while 100x100 already generates about
264 KB of TeX and takes about 10 seconds to compile locally. The boundary is a
conservative pre-1.0 choice between those measured points, not a globally
optimal cost model. Rectangular and square matrices use the same total cell
count. With multiple visible image layers, one figure-level choice is made from
the largest layer because the current render plan has one image backend.

## Reason codes

| Reason | Meaning |
| --- | --- |
| `explicit_vector` | The caller requested vector. |
| `explicit_hybrid` | The caller requested hybrid. |
| `small_scalar_image` | Auto found image layers at or below 4096 cells. |
| `dense_scalar_image` | Auto found an image layer above 4096 cells. |
| `no_image_layer` | Auto found no visible scalar image and selected vector. |
| `truecolor_requires_hybrid` | Truecolor semantics require a PNG image layer. |
| `alpha_requires_hybrid` | Nonopaque image-owned alpha requires a PNG image layer. |

Normal selection is not a warning. Policy metadata includes the stable name,
version, ID, and threshold so a saved result explains the decision.

## Determinism and boundaries

The planner receives validated, handle-free FigureIR. It does not inspect the
OS, graphics toolkit, monitor, publication width, compiler speed, or elapsed
time. It performs no trial compilation, retry, screenshot, or runtime
calibration. Equal FigureIR, request, and policy produce equal decisions.
Publication profiles therefore do not change the choice.

Capability analysis precedes planning. Rich modes select hybrid by explicit
semantic reason, not as an error fallback. A forced vector request for RGB or
nonopaque alpha fails with `M2T2:E053:UnsupportedVectorRichImage`. Hybrid's
uniform-coordinate requirement remains
an explicit render diagnostic.

## Figure sets

`m2t.exportSet(...,'ImageBackend','auto')` supplies an inherited request. A
nonempty per-entry `imageBackend` overrides it. Every entry delegates to
`m2t.export`, so planning is performed once by the same planner. Entry results
and schema-1 manifests record requested backend, selected backend, reason, and
policy ID. The existing `imageBackend` manifest field records the selected
representation; all additions are backward-compatible fields.

Users can override a policy result with explicit `vector` or `hybrid`. M3.5
does not expose thresholds or custom policy objects as public options and does
not plan backends for lines, scatter, errorbars, or whole figures.
