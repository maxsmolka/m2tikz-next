# MATLAB and Octave validation differences

M4.1 compares normalized scientific semantics rather than raw graphics trees.
The recorded runtimes are MATLAB R2026a Update 4 on Windows and GNU Octave
11.3. The F01-F26 scientific data, series kinds and ordering, explicit text,
image matrices, coordinates, explicit CLim, and explicit colormaps agree where
the fixtures define them.

## Observed graphics-object differences

| Area | MATLAB R2026a observation | Octave 11.3 observation | Normalization |
| --- | --- | --- | --- |
| Figure helper | Empty `matlab.graphics.shape.internal.AnnotationPane`, Type `annotationpane`, Tag `scribeOverlay`, handle visibility off, directly owned by the figure | No corresponding figure child in the validated fixtures | Ignore only the empty, figure-owned, tagged runtime pane; nonempty user annotations remain E001 |
| On/off properties | `Axes.Box` is `matlab.lang.OnOffSwitchState` | Character value | Convert the supported semantic value to lower-case text |
| Figure handles | A valid figure may arrive through a numeric legacy-handle container while its Parent is an HG2 object | Numeric graphics handles | Compare graphics identity with handle equality, not class-strict `isequal` |
| Scatter | `matlab.graphics.chart.primitive.Scatter`, Type `scatter` | Native scatter or capability-proven scatter `hggroup`, depending on toolkit | Both normalize to the existing constant-style ScatterIR |
| Errorbar | `matlab.graphics.chart.primitive.ErrorBar`, Type `errorbar` | Native/compound representation recognized by capability | Both normalize to the existing ErrorbarIR |
| Legend | `matlab.graphics.illustration.Legend`, Type `legend`, direct figure child with an `Axes` owner | Toolkit-dependent axes/legend ownership and possible hidden axes-text decoration | Ownership is resolved by properties/appdata; only proven legend decoration is excluded |
| Colorbar | `matlab.graphics.illustration.ColorBar`, Type `colorbar`, direct figure child with an axes owner | Toolkit-dependent colorbar representation | Both reuse ColorbarIR and explicit ownership resolution |
| Image | `matlab.graphics.primitive.Image` with scalar CData, scaled mapping, XData/YData and AlphaData | Image representation with equivalent supported capabilities | Both normalize to `m2t2.image`; RGB and relevant alpha remain explicit unsupported cases |

The MATLAB pane rule is deliberately narrow. Type, Tag, HandleVisibility,
parent identity, and empty children must all match. A user-created annotation
makes the pane semantically nonempty and remains unsupported. There is no
MATLAB-release, OS, or toolkit branch in product code.

## Normalized IR comparison

Cross-runtime comparisons classify all observed non-exact paths as expected
runtime defaults:

- source figure size;
- default color order and default colormap;
- automatically selected x/y limits;
- positions derived from default axes/colorbar geometry.

These defaults are not overwritten to force equality. Explicit scientific
values remain equal: F21 retains its requested CLim; F22 retains its requested
colormap and differs only in source size. Profile-driven physical output is
validated independently of source defaults.

The comparator uses exact equality for text, kinds, IDs, series ordering, and
discrete values; `1e-12` for scientific coordinates, data, colors, limits, and
ticks; and `1e-8` for normalized geometry. A declared runtime-default path is
classified `expected_runtime_difference`; undeclared differences remain
`semantic_mismatch`.

## Visual evidence subset

| Visual ID | Fixture | Review |
| --- | --- | --- |
| V01 | F08 line and legend | pass: two series and legend order preserved |
| V02 | F04 errorbar | pass: values and symmetric error extents preserved |
| V03 | F13 multiple axes | pass: axes count, order, and relative layout preserved |
| V04 | F15 vertical colorbar | pass: matrix orientation and range 1-4 preserved |
| V05 | F18 scalar image | pass: 2-by-3 orientation preserved |
| V06 | F22 custom colormap | pass: explicit four-color mapping preserved |
| V07 | F23 publication profile | pass: curve and physical profile geometry preserved |
| V08 | F25 hybrid heatmap | pass: raster orientation, extrema, axes, and vector colorbar preserved |

Pixel identity is neither expected nor required. Default palettes, page size,
and autoscaling produce visible but semantically classified differences.
