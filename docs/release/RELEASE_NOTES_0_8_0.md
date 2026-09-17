# m2tikz-next 0.8.0

Feature-freeze / pre-1.0 acceptance release. The immutable `v0.8.0` tag is the
reference for external real-world MATLAB testing before the 1.0 release-candidate
phase. This is not 1.0, production-complete software or universal MATLAB graphics
support. Source archives are provided by GitHub; no local validation artifacts
or external scientific data are bundled.

## Highlights

Since 0.5.0: rich scatter, RGB/alpha images, fixed modern tiled layouts, bounded
dual Y axes and broader bounded scientific 3-D; large-data, unsupported-object,
determinism/performance, API/IR, runtime and portability hardening. The release
also includes the publication-profile title-clipping fix and the local external
acceptance package. Release engineering adds no product features.

## Public API

The public entry points remain `m2t.export` and `m2t.exportSet`. Their defaults
and options are unchanged. The API-freeze candidate requires exceptional
justification, an ADR and migration notes for breaking changes. FigureIR remains
v2 with explicit compatibility/default/migration rules; manifest schema remains
1. Internal `m2t2.*` and validation helpers are not new public APIs.

## Scientific Correctness

- Preserve samples, pixel dimensions, NaN gaps, scientific ownership and order;
  no automatic downsampling, whole-figure rasterization or legacy fallback.
- Reject unsupported objects, ambiguous ownership, modified compounds and
  unrepresented properties before accepting misleading partial output.
- Preserve rich color/size roles and discrete scalar colormap classes.
- Publication sizing reserves physical text/colorbar gutters: short titles no
  longer clip at 85 mm. Typography, 85/170 mm widths and scientific data remain
  unchanged. P01-P13 plus default controls check actual PDF glyph/page bounds.
- Buffered large-image serialization preserves prior TeX bytes. Determinism
  tests cover repeated and cross-directory products without timing thresholds.

## Major Supported Areas

Bounded 2-D lines/error bars, rich scatter, legends/ticks/log/reversed axes,
multiple/manual axes, scalar and RGB images with image-owned alpha, colorbars,
axes text/figure arrows, grouped vertical bars and narrow traditional boxplots;
fixed MATLAB tiled layouts with supported spans/shared labels; bounded native
MATLAB dual Y line/scatter axes; orthographic Surface/Line3/Patch3, rich scatter3
and constant-color wire mesh. Every family retains its documented limits in the
[support matrix](https://github.com/maxsmolka/m2tikz-next/blob/v0.8.0/docs/SUPPORT.md).

## Runtime Evidence

Current release validation uses **MATLAB R2026a Update 5 on Windows** and
**GNU Octave 11.3 / gnuplot on Linux**, plus pinned hosted Octave 11.3 CI.
Historical Update 4 records remain historical. Native readers, portable IR,
real compiler/PDF checks and visual review are separate evidence layers.
Portable tiled/shared/dual-Y fixtures do not establish native Octave parity.
No external tester's MATLAB version is yet claimed as supported.

Local real compilation uses LuaLaTeX 1.22 / TeX Live 2025 Debian, PGFPlots,
latexmk and Poppler. Native MATLAB invokes this Linux compiler through a process
bridge; that is not native Windows TeX evidence. Hosted CI uses its runner
toolchain. Compilation alone is not a visual or scientific acceptance proof.

## Portability

Runtime hardening distinguishes absent optional properties from getter failures
and normalizes supported scalar MATLAB strings explicitly. The environment
contract covers observed Unicode/spaced/nested paths, lossless UTF-8 output,
asset-write diagnostics, actual compiler failures and common JSON/TeX goldens.
Decoded PNG pixels, not cross-encoder bytes, are compared. This is observed
compatibility, not a universal runtime/platform/Unicode guarantee.

## Feature Freeze

No new major graphics family is planned before 1.0 unless external acceptance
reveals a critical correctness/usability gap that cannot reasonably be deferred.
Correctness, diagnostics, compatibility/portability, performance-regression
fixes, documentation, security and release engineering remain in scope.
No M8.0 work or additional feature development is part of this release.

## Known Limitations

Dynamic/nested/zero-spacing tiled layouts, outer-tile decorations, unbounded
dual-Y variants, arbitrary 3-D scenes/perspective/lighting/materials, scatter
alpha, polar/contour families, general annotations/patches/bars/boxchart and
nonwhite axes remain outside the supported contract. Hybrid channels are 8-bit;
scientific TeX uses 15-significant-digit text rather than binary archival data.
PNG/PDF byte identity across encoders/engines is not promised. Very long titles,
manual overlaps and bounded 3-D viewport/tick proximity need visual review.
There is no built-in compiler timeout. Process trusted figures/text and TeX only.

## External Acceptance Testing

Clone `https://github.com/maxsmolka/m2tikz-next.git`, check out **`v0.8.0`**
(not moving `main`) and record `git rev-parse HEAD`. Follow
[the external acceptance guide](https://github.com/maxsmolka/m2tikz-next/blob/v0.8.0/docs/validation/EXTERNAL_ACCEPTANCE_TESTING.md)
with roughly 5-10 critical real figures. Compare scientific semantics and PDFs
manually; successful compilation initially remains `NEEDS_REVIEW`.
Keep figures, data, products and logs local; share only manually redacted findings
or minimal synthetic reproductions. Another MATLAB version becomes official
evidence only after actual results. Next: external testing, feedback triage,
M8.0 RC readiness, RC release and burn-in, then 1.0.

## Upstream Relationship

m2tikz-next is an independent project derived from matlab2tikz, not an official
upstream release or successor. It preserves upstream Git history, BSD-2-Clause
license, copyright, attribution and contributor records. The inherited
`matlab2tikz(...)` API remains separate from the modern pipeline.
