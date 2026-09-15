# M6.5 - Broader scientific 3-D

## Baseline and scope

Started from clean public main `35dbfd8930787a28a67da2f77f7f47bb1ca6ee86`
after M6.4 PR #8 passed all three required checks, merged and its branch was
removed. The branch for this phase is `m6.5/broader-scientific-3d`.
The latest actual release remains 0.5.0; no release/tag operation is included.
The preceding baseline passed its full portable/native acceptance gates.

## Implementation

- Rich Scatter3IR adds exact Z to existing size/color/edge/face roles and
  reuses axes ColorMappingIR and ColorbarIR.
- Conditional SurfaceIR wire semantics retain every grid vertex and emit all
  row/column polylines with explicit RGB, width and style. Default native mesh
  is not falsely treated as transparent wire.
- New scenes require explicit `sceneOrder`. One visible object is allowed in
  depth mode; scatter billboards are stably ordered far-to-near with XYZ,
  sizes and color metadata kept together in a renderer-local copy. Explicit
  native child order permits bounded line/surface/scatter/wire combinations.
- Camera modes are checked instead of guessed: orthographic, linear axes,
  automatic camera modes and plot box, non-polar view elevation. Manual
  target/roll/zoom, perspective and unresolved multi-object depth fail before
  output. Existing narrow Surface/Line3/Patch3 IR remains supported.
- E062/E063 distinguish unsupported camera and scene/decoration state.
  Renderer code remains handle-free. No reduction, raster fallback or public
  option has been added.

See [SCIENTIFIC_3D.md](docs/SCIENTIFIC_3D.md) and
[ADR-0024](docs/adr/ADR-0024-bounded-scientific-3d.md) for precise boundaries.
Contour3, additional patch topology, arbitrary opaque intersections, lighting,
materials, textures, arbitrary alpha, perspective and volumes remain excluded.

## Native MATLAB evidence

Validated with MATLAB R2026a Update 4 on Windows.

That sentence retains the historical evidence boundary. Newly collected
evidence in this phase uses MATLAB R2026a Update 5 on Windows, not all releases.
The native suite has 26 cases: coordinate/size/RGB/scalar mapping, colorbar,
single inside legend, wire mesh, wire and opaque-surface combinations, three
asymmetric views, aspect/reversal, depth/child ordering, no mutation, and
unsupported scene/camera/alpha/light/legend/mesh/top-view/log cases.
The final native result is recorded in the acceptance decision below.

Four public workflow cases exercise 85/170 mm exports and a repeated figure
set, including identical manifest text. Compilation uses an actual Linux
LuaLaTeX process reached from native MATLAB, not a compiler stub or a claim
that TeX is installed natively on Windows. The existing 29-case native rich
scatter suite also passed after shared renderer color-name changes.

## Portable and compilation evidence

The focused portable suite has 19 assertions covering explicit triples,
sizes/colors, stable depth/ties, reversal/aspect, child order, wire connectivity,
JSON replay, no mutation, malformed contracts and physical profile gutters.
Its seven focused TeX documents compile with real LuaLaTeX. Thirteen documents
generated from native figures are a separate compilation/visual lane.
The older ten-case Surface/Line3/Patch3 IR suite remains part of the checks.

GNU Octave 11.3 runs the portable suites; this does not claim native Octave
scatter3/mesh parity. Local compiler evidence is LuaTeX 1.22 and TeX Live
2025/Debian, distinct from the historical TeX Live 2026 baseline.
The full gate retains 140 core cases/eight curated compilations, 233 established
extended cases, nine rich-scatter and eleven rich-image compilations, and
S1/tiled/dual-Y foundation suites. Two obsolete blanket scatter3 negative tests
now specifically guard the 2-D reader/top-view rejection boundary, while new
native and portable suites establish the positive 3-D contract.

## Visual review and corrections

An asymmetric XYZ basis probe confirmed the supported view and aspect mapping.
Native overlapping near-red/far-blue markers proved different outcomes for
depth and child-order painting; compiled PDFs reproduce those outcomes.
Source/reference comparisons cover point locations, wire connectivity, RGB,
marker sizes, scalar/colorbar mapping, varied views and child-order overlays.

Visual inspection found a real deferred-drawing defect: different size runs
reused RGB definitions, so a later run could recolor earlier 3-D markers.
Runs and symbolic classes now have distinct deterministic names. The corrected
RGB/size PDF contains the expected separate red, green and blue points.

A second inspection found clipped axes labels in a technically successful
85 mm export. The profile now reserves physical gutters for new 3-D scenes,
with an independent east colorbar body and separation. Both 85/170 mm outputs
were recompiled and reviewed with complete X/Y/Z labels. Coordinates, camera,
source placements and marker semantics are unchanged. This is bounded profile
layout, not a general arbitrary-text fitting or camera solver.

## Documentation, security and integration

Current status/roadmap, README, architecture, support, workflow, profiles,
diagnostics, runtime evidence and tests document the new bounded slice.
The original surface ADR is explicitly historical and linked to its extension.
Required hosted jobs retain their names and protections; CI adds focused
portable 3-D IR and compiler lanes. No private paths, native runtime bridge,
credentials or private evidence files are part of the public changes.

## Acceptance decision

Final local acceptance passed on 2026-09-15: all 26 native cases, four real
profile/set cases, native 29-case prior-scatter regression, 19 portable cases,
seven portable and thirteen native-generated compilations, and final visual
review including surface/scatter/line and single-legend fixtures.
The full 140-core/eight-curated and 233-extended regression passed, along with
nine rich-scatter, eleven rich-image and all S1/M6.3/M6.4 foundation cases.
All six invariants, links, confidentiality, citation (0.5.0), actionlint and
whitespace checks passed. Earlier mixed-version runs were not used as the
final acceptance gate after profile corrections.

Local acceptance is complete, but this report does not claim hosted checks
or merge have already occurred. Integration still requires the three green
hosted jobs on the exact PR head. M6.6 starts only after verified merge and
local/remote milestone branch cleanup.
