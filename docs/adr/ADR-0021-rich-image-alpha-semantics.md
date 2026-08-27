# ADR-0021: Rich image and alpha semantics

Status: Accepted

## Context

The scalar image path already separates axes-owned color mapping from an image
layer and provides vector and hybrid representations. Truecolor and opacity
cannot be carried faithfully by the scalar PGFPlots matrix representation.

## Decision

ImageIR explicitly distinguishes scalar and normalized truecolor CData, plus
opaque, constant, and per-pixel image-owned alpha. Scalar CLim and colormap stay
axes-owned. Truecolor has no CLim semantics and never creates a colorbar.

Opaque scalar images may use vector or hybrid output. Truecolor or nonopaque
alpha requires the existing image-only hybrid PNG backend. `auto` reports
`truecolor_requires_hybrid` or `alpha_requires_hybrid`; forced vector fails
explicitly. PNG pixels retain exact dimensions and unpremultiplied 8-bit RGBA.
Axes, text, overlays, annotations, and colorbars remain vector.

Scalar `scaled` and bounded integer-valued `direct` mapping are explicit.
Floating RGB is accepted in `[0,1]`; uint8 and uint16 RGB are normalized by
their class maxima. Unmapped floating/uint alpha is normalized similarly.

## Consequences

The FigureIR v2 change is additive and old documents receive scalar/opaque
defaults. Identical normalized input and one encoder environment produce stable
asset bytes after time metadata removal; cross-encoder byte identity is not
claimed. There is no whole-figure raster fallback, resizing, downsampling, or
silent removal of color or alpha.
