# M5.1 semantic annotation support

M5.1 adds explicit axes-owned 2-D text plus figure-owned arrow and double-arrow
IR. Ownership, coordinate spaces, alignment, rotation, text interpreter,
stroke, and arrow-head style survive JSON replay and native PGFPlots rendering.
Arbitrary annotation shapes and unrelated groups remain explicitly unsupported.

Validation uses analytic curves and generic text/arrow fixtures. It covers
multiple axes, publication profiles, figure sets, determinism, lifecycle, and
LuaLaTeX compilation.
