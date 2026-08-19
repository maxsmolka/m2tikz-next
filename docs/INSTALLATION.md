# Installation

m2tikz-next currently uses a source checkout; no package-manager release exists.
The validated preview path is Windows first, but all documented commands use
`PATH` discovery and avoid machine-specific installation directories.

## Prerequisites

- Git
- GNU Octave
- a TeX distribution containing TikZ/PGF, PGFPlots, and LuaLaTeX
- PowerShell 7 for the consolidated validation script
- `latexmk`, Python, Poppler, Pillow, and `pdfplumber` for the complete visual
  validation matrices

The recorded baseline is GNU Octave 11.3, TeX Live 2026, PGFPlots 1.18.x, and
LuaLaTeX. These are validated versions, not invented minimum-version bounds.

## Windows setup

Install Git, GNU Octave, and TeX Live using their normal vendor-supported
installers, then start a new PowerShell session so their command directories are
on `PATH`. Clone the future public repository URL and enter the checkout:

```powershell
git clone https://github.com/maxsmolka/m2tikz-next.git
Set-Location m2tikz-next
```

Verify tool discovery:

```powershell
git --version
octave-cli --version
lualatex --version
kpsewhich pgfplots.sty
```

Add the source directory for the current Octave session:

```matlab
addpath('src');
disp(which('m2t2.export'));
```

For a persistent local setup, add the checkout's `src` directory through your
own Octave startup configuration. Do not commit that machine-specific path.

## Other operating systems

Use the platform package or TeX distribution that provides the same command-line
tools, then run the verification commands above. CI exercises a Linux path, but
the first recorded end-to-end preview baseline remains Windows; this is not yet a
broad operating-system support commitment.

## Verify the checkout

From PowerShell 7 at the repository root:

```powershell
./test/runPublicPreviewValidation.ps1
```

Generated validation files are written below ignored `.audit/public-preview/`.
See `docs/SUPPORT.md` for the evidence-backed feature boundary. The modern path
is validated with MATLAB R2026a Update 4 on Windows; no other MATLAB release is
implied.
## MATLAB validation status

M4.1 executed the noninteractive M4 harness with MATLAB R2026a Update 4 on
Windows. The evidence command and prerequisite checks are documented in
[MATLAB_TRIAL_EXECUTION_PLAN.md](MATLAB_TRIAL_EXECUTION_PLAN.md), and actual
results are grouped in [MATLAB_VALIDATION_MATRIX.md](MATLAB_VALIDATION_MATRIX.md).
The exact detected release - not "MATLAB" generally - is the support scope.
