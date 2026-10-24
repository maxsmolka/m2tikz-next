# Installation

m2tikz-next is currently distributed as a source checkout. There is no package
manager release or installer.

## Validated runtime boundary

Choose one figure runtime:

- **GNU Octave:** version 11.3 is exercised by hosted Linux CI and local
  validation.
- **MATLAB:** broad historical release evidence uses R2026a Update 5 on Windows;
  focused legend/gallery/timeout patch evidence uses R2026b on Windows. These
  observations do not qualify all workflows on every version or platform.

Both runtimes use the same public `m2t.*` workflow. Platform packages or vendor
installers may be used, but the commands must be discoverable on `PATH` for the
portable validation scripts.

Historical milestones retain their original Update 4 evidence. Current validation
uses Update 5 and local LuaLaTeX / TeX Live 2025/Debian. See the
[validation matrix](MATLAB_VALIDATION_MATRIX.md); the historical Update 4
claim does not imply other versions. Public calls follow [API.md](API.md).
The [environment contract](ENVIRONMENT_CONTRACT.md) distinguishes Windows
MATLAB, container/hosted Linux Octave and the actually observed TeX toolchains.
MATLAB must run with its JVM enabled for safe output-path checks.

R2026b no longer bundles a JRE. Configure a supported OpenJDK/JRE before
exporting: [MathWorks Java setup](https://www.mathworks.com/help/matlab/matlab_external/configure-your-system-to-use-java.html).
The safe path checks also apply to R2026b and cannot be bypassed without Java.

## Process supervision (new in 0.8.1)

- Linux/POSIX: install **Python 3** using your platform's package manager and
  verify `python3 --version`. Its standard library is sufficient; no pip
  packages are needed for export.
- Windows: built-in **Windows PowerShell/.NET** supplies the supervisor. Python
  is not required for Windows export. Local policies must permit its repository
  helper script and Add-Type; supervision failures report C007, not an
  unbounded fallback. Do not weaken execution/security policies automatically.

Budgets are 15 seconds for the compiler version probe and 300 seconds per
compilation. These do not bound total export time or detached/remote jobs.

## TeX toolchain

Successful `m2t.export` calls compile standalone PGFPlots documents. The
validated toolchain is:

- TeX Live 2026;
- LuaLaTeX;
- TikZ/PGF and PGFPlots 1.18.x;
- the LaTeX `standalone` class.

That is the historical preview toolchain. New local compatibility/portability
runs also use TeX Live 2025/Debian. The MATLAB validation bridge reaches Linux
LuaLaTeX; a native Windows TeX distribution must be independently verified.

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

Record your MATLAB/Octave version, OS, checkout commit and compiler version
locally. Testing another MATLAB release creates new evidence only after the
tests actually run. Do not upload real figures, data, raw logs or screenshots
with an environment report unless you have reviewed and removed sensitive
content. Optional synthetic boxplot construction requires its runtime toolbox;
this is not a claim that every validation fixture runs in base MATLAB only.

## Verify with a minimal export

Start MATLAB or Octave in the repository root after confirming that LuaLaTeX is
on `PATH`, then run:

```matlab
addpath('src');
x = linspace(0, 2*pi, 200);
figure('Color','w');
plot(x, sin(x));
set(gca,'Color','w'); % Explicit supported background, independent of theme.
result = m2t.export(gcf, 'build/installation-check');
assert(result.success, result.status);
disp(result.texPath);
disp(result.pdfPath);
```

The output base determines where generated files go. This example creates
`build/installation-check.tex`, `build/installation-check.pdf`, and compiler
diagnostics beside them. Existing products are preserved by default; pass
`'Overwrite', true` only when replacement is intended.

Inspect both `result.diagnostics` and the rendered PDF. Missing LuaLaTeX,
compilation failure and missing/invalid PDFs have distinct codes. Logs are
local and may include sensitive paths or labels. Export calls are synchronous
with internal compiler deadlines (15-second discovery, 300-second compilation);
POSIX requires Python 3 on PATH for supervision. Windows uses its built-in
Windows PowerShell/.NET and does not require Python for export. Still supervise
untrusted or unusually slow jobs outside
the API. Only trusted TeX/LaTeX-interpreted labels should be exported.

Use `fullfile` for output folders. Spaces and the observed `äöü` path cases are
tested; generated text is UTF-8 without BOM and generated line endings are LF.
For hybrid output, keep the companion `-assets` directory beside the TeX file.

## Platform notes

Hosted CI validates GNU Octave 11.3 on Linux. Current release validation uses
MATLAB R2026a Update 5 on Windows; earlier Update 4 records remain historical.
File discovery and export paths are designed
to be portable, but these evidence boundaries do not claim validation for every
operating system or runtime release. See [Support status](SUPPORT.md) and the
[MATLAB validation matrix](MATLAB_VALIDATION_MATRIX.md).

On Windows systems with more than one TeX distribution, ensure `lualatex` on
`PATH` resolves to the intended, fully initialized installation. `where
lualatex` and `lualatex --version` should agree before starting MATLAB or
Octave; path order determines which compiler `m2t.export` invokes.

## Repository validation

From PowerShell 7 at the repository root:

```powershell
./test/runPublicPreviewValidation.ps1
```

The script writes generated validation products only below ignored `.audit/`
directories. It is broader than the minimal installation check and exercises
repository policy, readers, renderers, examples, and TeX preview compilation.
