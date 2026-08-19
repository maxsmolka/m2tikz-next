# ADR-0010: Image and matrix representation

- Status: Accepted
- Date: 2026-08-12

## Context

Scientific publications frequently contain scalar matrix plots. The existing
line/scatter IR cannot express matrix orientation or axes-owned scalar color
mapping without conflating unrelated semantics. Runtime image properties also
vary: GNU Octave 11.3 exposes two-value XData/YData endpoint pairs even when a
caller supplied full uniformly spaced vectors.

## Decision

Add the handle-free `m2t2.image` series kind with cell-center `x` and `y`, exact
rows(y)-by-columns(x) `cdata`, scaled mapping, and nearest-cell interpolation.
The reader expands endpoint pairs deterministically and preserves CData without
transpose, reversal, resampling, or normalization. Axes directions express
orientation. Axes `colorMapping` and existing ColorbarIR remain authoritative.

Render an explicit PGFPlots `matrix plot*` table with one row per cell. Each row
contains X, Y, the original scalar value, and its deterministic direct colormap
index. Explicit colormap stops use the shared 15-significant-digit formatter.
This avoids unstable runtime names and TeX-side default-colormap differences,
while matching discrete scaled-image binning. `NaN` is a missing cell; infinity,
RGB, alpha, direct-indexed CData, nonlinear CData scales, and invalid coordinates
are explicit unsupported diagnostics.

The representation intentionally grows linearly with cell count. Evidence shows
250x250 pure PGFPlots output is already expensive; M3.3 does not downsample or
silently select another backend.

## Consequences

- Image data remains replayable, deterministic, handle-free, OS-unaware, and
  toolkit-unaware after the reader boundary.
- The publication profile changes physical presentation only.
- `m2t.exportSet` needs no image-specific logic.
- MATLAB support remains unvalidated until external runtime evidence exists.
- Future non-uniform coordinate vectors require runtime evidence because Octave
  currently reduces common `imagesc(x,y,Z)` inputs to endpoints.

## Rejected alternatives

- Screenshot or PNG fallback: loses the normalized scientific representation.
- Encoding every cell as scatter: abuses series semantics and complicates
  orientation and cell geometry.
- Runtime queries from the renderer: violates the reader/renderer boundary.
- Silent legacy-export fallback: hides capability and validation failures.
