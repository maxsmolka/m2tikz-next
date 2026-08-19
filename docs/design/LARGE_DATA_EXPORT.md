# Large-data export design notes

## Current state and limits

matlab2tikz serializes plot coordinates into PGFPlots input, inline by default or
as external tabular data when requested. M0 measured roughly 45 seconds and 37 MB
of inline TeX for one million points; LuaLaTeX took roughly 131 seconds, while
pdfTeX reached its memory limit already around 100,000 points. Export size and TeX
parsing cost currently scale approximately linearly with the number of samples.

These figures are an environment baseline, not performance promises. The
reproducible `benchmarks/benchmarkLargeData.m` matrix records both inline and
external-data modes at 100, 10,000, 100,000, and 1,000,000 points.

## Candidate strategies

| Strategy | Strength | Cost or risk |
|---|---|---|
| Data reduction | Largest size and compile-time win when visual resolution is lower than sample density | Must preserve extrema, discontinuities, uncertainty, and scientific meaning; never silently discard data |
| PGFPlots external data | Keeps TeX source small and data reusable | TeX still parses every point, adds file-management and relative-path concerns |
| Vector PDF asset | Fast inclusion and faithful vector rendering | Text is no longer naturally integrated with document fonts; very dense paths can remain large |
| SVG asset | Useful intermediate for web/vector toolchains | TeX inclusion needs conversion and has uneven package/tool support |
| Raster asset | Bounded size and compilation cost for dense images | Resolution-dependent, loses vector editing/search, poor for sparse line art |
| Hybrid axes plus asset | Keeps TeX labels/ticks while rendering dense content externally | Alignment, clipping, transparency, color management, and reproducibility become more complex |
| Automatic export planner | Could select a representation from plot complexity and target constraints | Requires reliable cost models, explicit policy, explainable diagnostics, and user override; a wrong automatic choice harms scientific output |

## Direction for a later 2.0 phase

Do not optimize or downsample automatically in M1A. First define measurable
quality constraints and an explicit representation contract. A future planner
should inspect object type, point count, visual density, transparency, target
engine, and archival requirements; emit a proposed plan and diagnostic; and allow
the user to force inline, external, vector, raster, or hybrid output. Data
reduction must be opt-in unless its semantic equivalence is demonstrable.
