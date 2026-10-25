# Axes legend layout

Version 0.8.2 additionally accepts `southoutside`, including two-row
horizontal legends below the X ticks/label. This lower placement is **not**
in the immutable v0.8.1 release; use `v0.8.2` or a reviewed later revision.
The existing upper placement remains unchanged.

This is an external-acceptance correction after v0.8.0. The immutable v0.8.0
release still rejects horizontal/multicolumn and upper outside legends.

## Development contract

The reader preserves actual legend links, membership, label order/interpreters
and frame suppression. Horizontal legends retain explicit positive integer
`NumColumns`; entries fill rows left to right, with a possibly incomplete final
row. Historical vertical one-column legends keep their previous defaults.

`northoutside` places the legend above one logical Cartesian 2-D axes, including
one-cell tiled and supported dual-Y configurations. A title stays between plot
and legend. Publication profiles reserve physical upper space based on rows
and fixed typography. Caller figures and legend settings are not changed.

`southoutside` uses the same one-logical-2-D boundary, placing the legend below
the X ticks and label. Six entries with `NumColumns=3` produce two rows:

```matlab
legend('show', 'Orientation','horizontal', 'NumColumns',3, ...
    'Location','southoutside');
result = m2t.export(fig, fullfile('.audit','lower-legend'), ...
    'Profile','publication','Width','double-column');
```

Publication profiles reserve lower physical space for the row count in both
85/170 mm modes. Without a profile, call `m2t.export(fig, outputBase)` without
`Width`: source size/axes geometry are unchanged, so the source must already
have enough bottom margin. A legend outside the page fails compilation rather
than silently moving the source axes, reducing columns/fonts or widening the
PDF. Long/custom tick labels, multiline/custom X labels and other manually
placed lower decorations still require visual review; this is not a general
collision-avoidance engine. See [ADR-0028](adr/ADR-0028-lower-outside-legends.md).

The actual interpreted TeX matrix is measured against the physical figure.
Overflow stops compilation with `M2T:C003:CompilationFailed` and a retained log
explaining `Legend exceeds figure bounds`, instead of producing a cropped PDF.
Long six-column legends may need 170 mm rather than 85 mm:

```matlab
result = m2t.export(fig, fullfile('.audit','legend-test'), ...
    'Profile','publication','Width','double-column');
```

Vertical multicolumn layouts, manual positions, east/west/other outside locations,
outside legends on multiple/3-D axes, titled/reversed legends and unresolved
ownership remain unsupported. Text, columns and page width never shrink or
change automatically to make an oversized legend fit.

## Evidence

`runHorizontalLegendTests` covers native/portable readers, order and caller
state, old JSON defaults, invalid fields, six/three/one-column layouts, titles,
one-cell tiled/dual-Y integration, deterministic output and actual overflow.
Ten synthetic PDFs per runtime are checked by
`checkHorizontalLegendPdfGeometry.py` for glyph/page bounds, dimensions,
row/column order, label presence and title/plot separation.

Native testing uses MATLAB R2026b (26.2.0.3386108) on Windows with a JVM and
real Linux LuaLaTeX through the existing local bridge. This does not qualify
native Windows TeX or MATLAB R2022a. The real external FIG and all products
stay local. White process defaults restore the legacy figure's default colors;
its data and legend state are checked unchanged after export.

`runSouthOutsideLegendTests(out,true)` adds nine portable PDF layouts (source
size, 85/170 mm, no/long X label, ragged rows, single-cell tiled, dual-Y and
vertical one-column), plus three native MATLAB public export workflows. It
checks actual two-row source reading/order and caller preservation, negative
multi-axes/3-D/layout cases, default-profile identity, lower overflow and too-
wide text. The shared PDF checker verifies row/column order, label presence,
page/glyph bounds and separation from the plot, X label and title. Native
evidence is scoped to R2026b with the existing Linux compiler bridge; it does
not establish R2022a/native Windows MiKTeX qualification or native Octave
multicolumn support when that runtime lacks `NumColumns`.
