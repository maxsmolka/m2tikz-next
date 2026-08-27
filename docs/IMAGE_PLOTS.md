# Image and matrix plots

The modern workflow supports a bounded 2-D image contract: scalar scientific
matrices and truecolor RGB arrays, with explicit image-owned opacity.

M3.4 additionally provides an explicit compact PNG data-layer representation.
M3.5 adds opt-in deterministic selection. See
[IMAGE_BACKENDS.md](IMAGE_BACKENDS.md) and
[BACKEND_PLANNER.md](BACKEND_PLANNER.md); vector remains the default.

## Supported scope

- nonempty scalar 2-D `CData` with `CDataMapping="scaled"` or integer-valued
  `direct` indices;
- M-by-N-by-3 double/single RGB in `[0,1]`, plus uint8 and uint16 RGB;
- unmapped opaque, constant, or image-sized per-pixel alpha in `[0,1]`;
- implicit matrix-index coordinates and explicit finite monotonic X/Y extents;
- normal and reversed axes directions;
- axes-owned `CLim`, explicit colormaps, and existing ColorbarIR elements;
- `NaN` as a missing cell;
- the publication profile (compatibility identifier `publication`), multiple axes, and figure sets.

ImageIR distinguishes `scalar` from normalized `rgb`, and `opaque`, `constant`,
and `per_pixel` alpha. It contains the
expanded cell-center vectors `x` and `y`, but never a graphics handle. Octave
may expose an endpoint pair even when full vectors were supplied to `imagesc`;
the reader deterministically expands that pair with `linspace` to one center per
matrix column or row. No transpose, row reversal, resampling, normalization, or
downsampling occurs. Axes `XDir` and `YDir` remain explicit renderer options, so
the source orientation is preserved without mutating the matrix.

## Color mapping

The axes-level `colorMapping` remains authoritative for limits and colormap
rows. Colormap components use the existing locale-independent 15-significant-
digit number formatter. The renderer emits the exact scalar CData value and a
deterministically derived PGFPlots direct color index for every cell. For an
N-row colormap and linear limits `[low, high]`, the zero-based index is:

```text
min(max(floor((value - low) / (high - low) * N), 0), N - 1)
```

This matches scaled image binning, including clamping, while preserving the
original value in the generated table. The already-existing ColorbarIR owns the
colorbar range, ticks, label, direction, orientation, and placement; the image
path does not create a second colorbar model.

## Alpha, truecolor, and unsupported content

Scalar `NaN` is a missing transparent cell; Inf is rejected. RGB never acquires
CLim or a synthetic colorbar. RGB and nonopaque alpha require the hybrid backend,
which preserves an 8-bit RGB/alpha PNG without resizing or premultiplication.
RGB NaN, mapped alpha, malformed shapes/ranges, nonuniform hybrid coordinates,
and unsupported dimensions fail with the documented M6.2 diagnostics.

MATLAB representation remains an external validation gate. The reader uses
properties and capabilities rather than OS, toolkit, or Octave-version checks.

## Performance

The pure PGFPlots table contains one row per matrix cell and preserves every
value. Local Windows Octave 11.3 / TeX Live 2026 evidence was:

| Matrix | TeX bytes | Reader | Renderer | LuaLaTeX |
| --- | ---: | ---: | ---: | ---: |
| 25x25 | 29,536 | 0.033 s | 0.346 s | 2.32 s |
| 100x100 | 290,000 | 0.017 s | 14.08 s | 20.00 s |
| 250x250 | 1,827,501 | 0.018 s | 84.53 s | 108.26 s |

Times are measurements, not guarantees. Around 100x100 is already noticeably
expensive for interactive rebuilds; 250x250 is impractical for routine pure-
PGFPlots use. `ImageBackend='hybrid'` remains explicit, while the opt-in
`ImageBackend='auto'` policy selects vector through 4096 cells and hybrid above
that boundary. It performs no runtime benchmarking or downsampling.

## Example

Run the generic Gaussian-residual example from the repository root:

```matlab
addpath('examples/08-scientific-heatmap');
result = example_scientific_heatmap();
```

It demonstrates explicit X/Y extents, normal Y direction, custom limits and
colormap, a colorbar, and `Profile="publication"`.
