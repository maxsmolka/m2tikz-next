# Axes legend layout

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

The actual interpreted TeX matrix is measured against the physical figure.
Overflow stops compilation with `M2T:C003:CompilationFailed` and a retained log
explaining `Legend exceeds figure bounds`, instead of producing a cropped PDF.
Long six-column legends may need 170 mm rather than 85 mm:

```matlab
result = m2t.export(fig, fullfile('.audit','legend-test'), ...
    'Profile','publication','Width','double-column');
```

Vertical multicolumn layouts, manual positions, other outside locations,
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
