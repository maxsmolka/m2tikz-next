# M5.4 narrow 3-D scientific surface

M5.4 implements a deliberately narrow Cartesian 3-D contract: orthographic
axes, scalar-colored SurfaceIR, Line3IR, narrow triangular Patch3IR, ColorBarIR,
and native PGFPlots output. It does not imply generic 3-D, lighting,
transparency, mesh, scatter3, or whole-figure raster support.

Validation uses analytic trigonometric and Gaussian surfaces plus explicit
synthetic IR for Line3 and Patch3. Geometry, scalar color mapping, view,
colorbar ownership, profiles, JSON replay, determinism, lifecycle, and
diagnostics remain covered.
