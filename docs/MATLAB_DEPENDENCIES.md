# MATLAB validation dependencies

The modern pipeline was executed with MATLAB R2026a Update 4 on Windows. Its
reader, IR, renderer, profile, set, image, hybrid, and planner paths completed
without an observed call to an optional MathWorks toolbox API.

## MathWorks products

The exercised APIs are ordinary MATLAB graphics and language facilities:
figures/axes, line/scatter/errorbar/image/colorbar/legend, numeric and struct
operations, JSON, filesystem I/O, `onCleanup`, process invocation, and
`imwrite`. Source inspection finds no modern call targeting Statistics and
Machine Learning, Signal Processing, Image Processing, Parallel Computing, or
another optional toolbox.

The trial runtime's installed-product audit listed MATLAB plus many optional
products, including Image Processing Toolbox. Consequently M4.1 cannot
empirically isolate a base-only installation. The evidence supports:

> No optional toolbox API was required by the observed modern validation path.

It does not yet support the stronger statement "Validated with base MATLAB
only." A future clean base-only installation or controlled license checkout is
needed for that claim. The inherited legacy exporter has a broader historical
surface and is reported separately.

## External executables

The compiled public workflow requires:

- `lualatex` on `PATH`;
- TeX `standalone`, TikZ, and PGFPlots compatible with 1.18;
- `pdfinfo` from Poppler for physical-PDF geometry checks in the full validation
  lane.

TeX Live 2026 supplied the successful validation toolchain. One ad hoc local
run selected a separate MiKTeX installation whose `luaotfload` cache was not
writable; that environment-only failure disappeared when the validated TeX
Live executable and a writable cache were selected. No product change was made
for it.

No ImageMagick, GUI display server, Java API, compiler SDK, or MathWorks
license-management API is required by the M4 validation harness. MATLAB itself
must be licensed locally; public GitHub Actions continues to use GNU Octave.

## Environment assumptions

- MATLAB R2026a Update 4, `win64`, Windows;
- writable ignored evidence directories and system temporary storage;
- noninteractive `matlab -batch` figures with `Visible='off'`;
- TeX Live LuaLaTeX and Poppler discoverable on `PATH`;
- no personal, proprietary, or machine-identity data in evidence.
