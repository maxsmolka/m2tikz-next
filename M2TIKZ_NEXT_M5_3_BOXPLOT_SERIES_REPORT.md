# M5.3 semantic boxplots

M5.3 adds a BoxplotSeriesIR for resolved quartiles, median, whiskers, outliers,
positions, styles, and legend semantics. Renderer input is handle-free and
statistics are never recomputed. Unsupported compound variants remain explicit.

Redistributable tests construct independent synthetic statistics and MATLAB
figures. They cover styles, outliers, layouts, profiles, figure sets, JSON
replay, determinism, lifecycle, negative controls, and LuaLaTeX compilation.
