# Publication profiles

> Public profile options belong to the [API-freeze candidate](API.md).
> Profile implementation helpers remain internal.

Publication profiles are deterministic, opt-in transformations between the
normalized FigureIR and the handle-free PGFPlots renderer. They change physical
presentation without mutating the MATLAB/Octave figure or its scientific
content.

## Available profiles

`Profile="none"` is the default. It preserves the M3.0 renderer configuration
and source FigureIR size. Omitting `Profile` and explicitly selecting `none`
produce byte-identical TeX for the same FigureIR.

`Profile="publication"` selects the conservative, TeX-native publication
presentation:

```matlab
result = m2t.export(gcf, 'figures/result', ...
    'Profile', 'publication', 'Width', 'single-column');
```

M5.6 calibrated and ratified these normative values with public synthetic
acceptance fixtures:

| Setting | Default |
| --- | ---: |
| Single-column width | 85 mm |
| Double-column width | 170 mm |
| Base text | 9 pt |
| Axes labels | 9 pt |
| Title | 10 pt |
| Tick labels | 8 pt |
| Legend | 8 pt |
| Colorbar label | 9 pt |
| Colorbar tick labels | 8 pt |

The default width is `single-column`. Widths are stored in the profile
definition in millimetres and converted deterministically to TeX points. The
standalone PDF page has no added profile border, so its physical width matches
the requested preset (allowing normal TeX/PDF rounding). Numeric custom widths
and unit parsing are deliberately deferred.

Height preserves the source FigureIR aspect ratio. Ratios below 0.45 or above
1.25 are clamped with the structured warning `M2T:PROFILE_ASPECT_CLAMPED` to
avoid unusably short or tall pages. Invalid source geometry fails during
analysis with `M2T:PROFILE_GEOMETRY_INVALID`.

## What is preserved

For untiled figures the transform changes only FigureIR physical size; relative
axes, overlay, subplot, colorbar and shared-element placements remain unchanged.
Explicit tiled layouts additionally use the documented per-cell text-gutter
policy below; their scientific data and logical ownership remain unchanged.
The render configuration applies portable TeX-native font sizes. It preserves:

- all data coordinates and error values;
- exact scalar image matrices, image cell centers, and axes directions;
- axis limits, scales, directions, explicit ticks, and tick labels;
- labels, titles, and `plain`, `tex`, or `latex` interpreter semantics;
- series order, legend membership, ownership, order, and location;
- color mapping and colorbar limits, ticks, scale, direction, and ownership;
- line widths, marker sizes, colors, and other supported series styling;
- axes-data text coordinates and figure-normalized arrow endpoints. Resizing
  transforms only FigureIR geometry; explicit font size, line width, color,
  rotation, alignment, and arrow-head dimensions remain style quantities;
- grouped-bar category centers, relative group offsets, widths, and baselines.
  Numeric data geometry remains in axes coordinates while edge width and colors
  remain explicit style values;
- boxplot group positions, resolved quartiles, medians, whiskers, and outliers.
  Profile scaling preserves statistical geometry and marker/line readability.

Known core text roles use the table above. User-authored axes annotations keep
their explicit source font size because it may encode intentional emphasis.
The profile does not relocate or reflow legends, clamp line widths or markers,
reduce outliers, or choose a width automatically. Colorbars keep relative
placements for untiled figures and follow their owning axes in tiled profiles.
The normative policy and figure-family width guidance are in
[PUBLICATION_PROFILE.md](PUBLICATION_PROFILE.md); its rationale is recorded
in [ADR-0019](adr/ADR-0019-calibrated-publication-profile.md).

The reader cannot currently distinguish explicit author styling from every
runtime default. The publication profile therefore uses a non-destructive
`preserve` policy for line widths and line/scatter marker sizes rather than
claiming to normalize defaults safely. Supported per-point scatter size and
color are preserved; marker shape stays constant and alpha is unsupported.
See [SUPPORT.md](SUPPORT.md). No downsampling or data simplification is performed.

## Result metadata and diagnostics

`result.profile` reports the applied `name`, width preset, width in
millimetres, final `figureSize`, and `figureSizeUnit` (`pt`). Unknown profiles
return `M2T:PROFILE_UNKNOWN`; unsupported or misplaced width values return
`M2T:PROFILE_WIDTH_INVALID`. These diagnostics use stage `analysis`, remain
machine-readable, and do not write export products.

## Limitations

The API has only `none` and `publication`; future profiles can add normalized
profile data without profile lookup in readers or renderers. There is no custom
width parser, font-family selection, automatic legend relocation, automatic
backend selection, arbitrary layout redesign, or arbitrary plot-type
support. Scalar image matrices use the same geometry-only transform; see
[IMAGE_PLOTS.md](IMAGE_PLOTS.md). The workflow remains PGFPlots plus LuaLaTeX.

Profiles may also be applied once as figure-set defaults. Entries can override
the existing profile or width properties without changing profile semantics:

```matlab
result = m2t.exportSet(entries, 'build/figures', ...
    'Profile', 'publication', 'Width', 'single-column');
```

See [FIGURE_SETS.md](FIGURE_SETS.md) for the exact inheritance rule and result
metadata.

Image-backend selection is orthogonal to publication profiles. Explicit hybrid
single- and double-column exports use identical one-cell-per-pixel assets and
change only physical vector placement and typography; auto decisions likewise
use cell count rather than physical width. See
[IMAGE_BACKENDS.md](IMAGE_BACKENDS.md) and [BACKEND_PLANNER.md](BACKEND_PLANNER.md).

For explicit fixed tiled layouts, M6.3 adds physical outer/per-cell text gutters
and shared-label anchors to the publication transform. Explicit grid slots and
spans place axes; colorbars follow their owners through relative affine transforms.
Tile cells and scientific series remain unchanged. This
prevents the observed shared-label collision at 85 mm without changing source
figures. It is not a general decoration solver, and figure-space annotations
fail this transform because safe ownership cannot be inferred. Untiled profile
behavior was unchanged in M6.3. M6.4 adds explicit right-side gutters for dual
Y axes, including a one-slot policy for a single untiled axes and extra
separation before an east colorbar. Multiple untiled dual axes fail the profile
transform. See [DUAL_Y_AXES.md](DUAL_Y_AXES.md).
Insufficient plotting area fails explicitly rather than
collapsing a dense grid. See [TILED_LAYOUTS.md](TILED_LAYOUTS.md).

M6.5 adds view-independent physical label gutters for the bounded new 3-D
scenes, including a one-slot policy for a single untiled axes. Multiple new
3-D axes require explicit tiled cells. East colorbars use an independent
8 pt body and physical separation. Source coordinates/view/aspect and source
figure placements remain unchanged; see [SCIENTIFIC_3D.md](SCIENTIFIC_3D.md).
