# Installation

m2tikz-next is currently distributed as a source checkout. There is no package
manager release or installer.

## Validated runtime boundary

Choose one figure runtime:

- **GNU Octave:** version 11.3 is exercised by hosted Linux CI and local
  validation.
- **MATLAB:** validated with MATLAB R2026a Update 4 on Windows. No other MATLAB
  release or operating system is implied by that statement.

Both runtimes use the same public `m2t.*` workflow. Platform packages or vendor
installers may be used, but the commands must be discoverable on `PATH` for the
portable validation scripts.

## TeX toolchain

Successful `m2t.export` calls compile standalone PGFPlots documents. The
validated toolchain is:

- TeX Live 2026;
- LuaLaTeX;
- TikZ/PGF and PGFPlots 1.18.x;
- the LaTeX `standalone` class.

LuaLaTeX is the workflow compiler, not a MATLAB or Octave dependency. Verify the
required commands and packages independently:

```console
lualatex --version
kpsewhich pgfplots.sty
kpsewhich standalone.cls
```

## Optional validation tools

Git and PowerShell 7 are needed for checkout and the consolidated repository
gate. Some extended visual or legacy validation paths additionally use
`latexmk`, Python, Poppler, Pillow, and `pdfplumber`; they are not required for
an ordinary single-figure export.

## Install from source

```console
git clone https://github.com/maxsmolka/m2tikz-next.git
cd m2tikz-next
```

Add the checkout's `src` directory in the MATLAB or Octave session:

```matlab
addpath('src');
assert(~isempty(which('m2t.export')));
```

For persistent use, add that absolute `src` directory through your local MATLAB
or Octave startup configuration. Do not copy or commit a machine-specific path
into the repository.

## Verify with a minimal export

Start MATLAB or Octave in the repository root after confirming that LuaLaTeX is
on `PATH`, then run:

```matlab
addpath('src');
x = linspace(0, 2*pi, 200);
figure;
plot(x, sin(x));
result = m2t.export(gcf, 'build/installation-check');
assert(result.success, result.status);
disp(result.texPath);
disp(result.pdfPath);
```

The output base determines where generated files go. This example creates
`build/installation-check.tex`, `build/installation-check.pdf`, and compiler
diagnostics beside them. Existing products are preserved by default; pass
`'Overwrite', true` only when replacement is intended.

## Platform notes

Hosted CI validates GNU Octave 11.3 on Linux. The recorded MATLAB validation is
MATLAB R2026a Update 4 on Windows. File discovery and export paths are designed
to be portable, but these evidence boundaries do not claim validation for every
operating system or runtime release. See [Support status](SUPPORT.md) and the
[MATLAB validation matrix](MATLAB_VALIDATION_MATRIX.md).

## Repository validation

From PowerShell 7 at the repository root:

```powershell
./test/runPublicPreviewValidation.ps1
```

The script writes generated validation products only below ignored `.audit/`
directories. It is broader than the minimal installation check and exercises
repository policy, readers, renderers, examples, and TeX preview compilation.
