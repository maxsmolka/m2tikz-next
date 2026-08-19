# M3.1 publication profile

M3.1 introduced an opt-in presentation transform for publication figures.
The public API identifier is `Profile='publication'`.

The profile supplies 85 mm and 170 mm width presets, deterministic physical
sizing, and coherent title/label/tick/legend typography. It preserves
scientific data, source-authored styles, layout, and default unprofiled output.
Public tests use independent line, scatter, errorbar, multiple-axes, colorbar,
and legend fixtures and compile them with LuaLaTeX.
