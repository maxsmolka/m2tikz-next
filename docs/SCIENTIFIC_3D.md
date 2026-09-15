# Bounded scientific 3-D

M6.5 adds native MATLAB `scatter3` and an explicit wire-mesh slice to the
existing orthographic Surface/Line3/narrow Patch3 foundation. It does not
introduce a general scene renderer or change the public export options.

## Coordinates, camera and ordering

The new slice requires finite XYZ data, orthographic projection, linear X/Y/Z,
automatic camera position/target/up-vector/view-angle modes, automatic plot-box
aspect mode, and elevation strictly between -90 and 90 degrees. MATLAB `view`
azimuth/elevation and resolved data-aspect ratios map to PGFPlots view and
inverse unit-vector ratios; axis reversals remain explicit. Manual camera
target, roll, zoom, perspective, logarithmic 3-D and top/bottom views are not
approximated. The reader does not change camera modes or object order.

New scenes store `AxesIR.sceneOrder` explicitly:

- `depth`: one visible scatter or constant-color wire mesh. Scatter billboards
  are ordered far-to-near using view, aspect and axis directions; equal-depth
  ties retain input order. XYZ, sizes and active colors are permuted together
  only in a renderer-local copy. Multiple depth-sorted objects are rejected:
  per-series PGFPlots rendering is not a scene-wide occlusion algorithm.
- `childorder`: the source axes explicitly requests ordered painting, without
  inter-object depth sorting. Supported Line3/surface/wire/scatter combinations
  preserve that order. No export option silently changes the source setting.

See the documented MATLAB [axes SortMethod and camera properties](https://www.mathworks.com/help/matlab/ref/matlab.graphics.axis.axes-properties.html).
This additional contract does not retrospectively broaden the older narrow
surface/compound evidence. Arbitrary intersecting opaque scenes remain outside
the claim. Additional contour3/patch topology has not been introduced.

## Scatter and color

`m2t2.scatter3` extends the rich scatter fields with mandatory Z coordinates;
it requires 3-D axes and explicit scene order. Constant/per-point marker areas,
constant RGB, per-point RGB and scalar mapped color reuse the 2-D role rules.
Scalar metadata uses the existing axes ColorMappingIR and ColorbarIR. Opaque
scatter uses discrete colormap row classes; original scalar values remain in
TeX. Interpolated surfaces interpolate scalar values before discrete mapping,
not vertex RGB. Finite colorbars use the same intervals (M6.6 correction).
Opaque edge/face roles and supported marker shapes are unchanged; alpha is rejected.
Variable sizes create exact contiguous plot runs, with distinct names for
deferred PGFPlots colors/classes. No point or color is reduced or quantized.
Single-scatter legends in the existing inside-location slice are supported
(default outside 3-D legends are not); mesh/multi-object legends and free 3-D
annotations remain explicit unsupported cases.

## Mesh

The new wire slice requires native Surface `FaceColor='none'`, a constant RGB
`EdgeColor`, `MeshStyle='both'`, a visible supported line style, opaque alpha,
and equal finite X/Y/Z/C matrices of at least 2-by-2. SurfaceIR uses
`faceMode='none'`, `edgeMode='constant'`, `edgeColor`, `lineWidth`, `lineStyle`.
Rendering emits all row and column polylines, preserving vertices and grid
connectivity without filled faces, hidden-line removal or rasterization.

Default MATLAB `mesh` can have opaque white faces and mapped edge colors; it
is **not** silently converted to this wire slice. Mapped edges, face textures,
lighting/materials, arbitrary transparency and volume rendering are excluded.
The existing interpolated scalar surface contract remains unchanged.

## Evidence and diagnostics

New native evidence is MATLAB R2026a Update 5 on Windows. Tests cover RGB/size,
mapped scatter/colorbar, depth versus child order, wire mesh, combinations,
three asymmetric views, aspect/reversal, lifecycle and explicit failures.
Portable Octave IR and real Linux LuaLaTeX/TeX Live 2025/Debian compilation are
separate evidence; they do not claim native Octave scatter3/mesh parity.
Native public exports also exercise 85/170 mm profiles and repeated sets.
Profiles reserve physical 3-D label gutters; multiple new 3-D axes require
explicit tiled cells. Source-size exports retain the original placements.

`M2T2:E062:Unsupported3DCamera` and `M2T2:E063:Unsupported3DScene` reject
unrepresented camera/ordering/decoration semantics before product creation.
Existing surface, scatter, projection, lighting and malformed-data diagnostics
remain in use. Malformed portable IR fails `M2T2:E003:InvalidIR`.
