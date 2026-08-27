# Image rendering backends

Image plots support two rendering representations and an opt-in planner
through the existing public workflows. The default remains the M3.3 vector
representation:

```matlab
vector = m2t.export(gcf, 'figures/field', 'ImageBackend', 'vector');
hybrid = m2t.export(gcf, 'figures/field', 'ImageBackend', 'hybrid');
automatic = m2t.export(gcf, 'figures/field', 'ImageBackend', 'auto');
```

Unknown values return `M2T:IMAGE_BACKEND_UNKNOWN`. `auto` uses the documented
deterministic 4096-cell policy; omitted options do not activate it. See
[BACKEND_PLANNER.md](BACKEND_PLANNER.md).

## Vector and hybrid modes

`vector` emits one PGFPlots matrix-table row per opaque scalar cell. It retains the
M3.3 output byte-for-byte and is useful for small matrices or workflows that
require the cell data directly in TeX.

`hybrid` converts only each image layer to a lossless PNG. PGFPlots
places the PNG through `addplot graphics` at explicit scientific cell edges.
Axes, ticks, labels, titles, legends, colorbars, shared elements, lines,
scatter, and errorbars remain vector content. It is not a screenshot backend:
the renderer does not call `print`, `saveas`, or `getframe`, and the PNG is
derived only from normalized handle-free ImageIR.

## Scalar-to-color and resolution semantics

Both modes use the same axes-owned CLim and colormap. For N colormap rows and
linear limits `[low, high]`, a finite scalar maps to the clamped zero-based row:

```text
min(max(floor((value - low) / (high - low) * N), 0), N - 1)
```

Hybrid RGB components are the selected normalized colormap row rounded to the
nearest 8-bit channel value. One matrix cell becomes exactly one PNG pixel;
there is no resampling, averaging, monitor-DPI scaling, or lossy compression.
Truecolor channels are normalized explicitly from floating, uint8, or uint16
source data. Constant and per-pixel alpha become the PNG alpha channel without
premultiplication. Fully opaque images omit an unnecessary alpha channel. A
scalar `NaN` cell has alpha zero.

PNG rows and columns are ordered for normalized numeric coordinates and axes
directions, so normal/reversed axes match vector orientation. Pixel edges are
one half-step beyond the first and last centers. Hybrid currently requires
uniformly spaced centers because one raster cannot express non-uniform cell
widths without resampling. Publication profiles alter physical placement only;
the same 250x250 ImageIR produces a 250x250 PNG at either publication width.

## Assets and overwrite lifecycle

For output base `figures/field`, hybrid mode writes:

```text
figures/
  field.tex
  field.pdf
  field-assets/
    image-0001.png
```

Visible image layers are numbered in deterministic axes/series render order.
The dedicated `<stem>-assets` directory is owned by that export. With
`Overwrite=false`, an existing TeX, PDF, log, or owned asset directory is a
collision. With `Overwrite=true`, only that exact directory is recreated,
eliminating stale assets without touching sibling files. Assets are written
only after successful analysis and planning; compilation failure retains PNGs
and the compile log for diagnosis.

`result.render` reports the legacy additive `requestedImageBackend` and
`effectiveImageBackend` fields, a structured `imageBackend` decision, and
absolute `assets` paths. Figure-set manifests retain schema version 1 and add
backward-compatible planner metadata plus relative `assets` fields.

## Figure sets

Set defaults and entry overrides use the M3.2 precedence rule:

```matlab
entries(1) = struct('figure', overview, 'name', 'overview', ...
                    'imageBackend', 'vector');
entries(2) = struct('figure', denseField, 'name', 'dense-field', ...
                    'imageBackend', []);
result = m2t.exportSet(entries, 'build/figures', ...
    'ImageBackend', 'hybrid', 'Overwrite', true);
```

The first entry is vector; the second inherits hybrid. `exportSet` still
delegates every figure to `m2t.export` and contains no image rendering logic.

## Performance guidance

Local Windows GNU Octave 11.3 / TeX Live 2026 measurements show the crossover:

| Matrix | Vector total | Vector LuaLaTeX | Hybrid total | Hybrid LuaLaTeX |
| --- | ---: | ---: | ---: | ---: |
| 25x25 | 17,171 B | 1.99 s | 1,268 B | 1.42 s |
| 100x100 | 263,636 B | 9.96 s | 1,888 B | 1.44 s |
| 250x250 | 1,722,125 B | 56.64 s | 3,228 B | 1.41 s |
| 500x500 | not run | not run | 5,665 B | 1.43 s |

Times depend on hardware and data compressibility. Hybrid is intended for dense
matrices; vector remains the default. The 500x500 vector case was not
run because the established coordinate-table scaling made it wasteful.

## Limitations

Hybrid supports scalar scaled/direct color and bounded truecolor/alpha modes.
Inf, RGB NaN, mapped alpha, nonlinear scalar color scale, and unsupported
dimensions remain unsupported. Non-uniform centers are rejected by
`M2T:IMAGE_HYBRID_COORDINATES_UNSUPPORTED`. MATLAB and hosted Linux execution
remain evidence gates; no OS/toolkit branches exist.
