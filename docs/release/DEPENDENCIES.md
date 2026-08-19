# Dependency inventory

No minimum version is inferred where the repository has not established one.

| Dependency | Role | Evidence/status |
|---|---|---|
| GNU Octave | Export runtime, tests, development | Version 11.3 validated in hosted Linux CI |
| MATLAB | Export runtime and reader validation | MATLAB R2026a Update 4 validated on Windows; no broader release/platform claim |
| PGFPlots | Generated TeX rendering | M2 renderer emits `compat=1.18`; validation used 1.18.x |
| TikZ/PGF | Generated TeX rendering | Required by PGFPlots and inherited exporter output |
| TeX Live | Validation tool distribution | Validation performed with TeX Live 2026 |
| LuaLaTeX | M3 workflow compiler and primary validation compiler | Discovered through `PATH`; validated for M2/M3 matrices |
| pdfLaTeX | Compatibility validation compiler | Validated with documented raw-Unicode limitation |
| `standalone` | M3 workflow and standalone test/PDF documents | Required by current standalone renderer output |
| `amsmath`, `grffile`, TikZ/PGFPlots libraries | Legacy export compilation | Emitted by inherited exporter as needed |
| PowerShell | Portable validation orchestration | Development/validation only |
| Bash and Git | Legacy ACID harness and repository operations | Test/development only |
| Python | Geometry and raster-comparison utilities | Validation only |
| Pillow | Pixel comparison (`m2VisualCompare.py`) | Validation only |
| pdfplumber | PDF rectangle extraction | Validation only |
| Poppler `pdftoppm` | PDF rasterization | Validation only |
| `latexmk` | Repeatable TeX compilation | Validation only |
| Octave `signal` package | Selected legacy ACID cases | Optional test dependency; never auto-installed |

## Runtime boundary

The handle-free M2 renderer consumes normalized IR and does not call MATLAB or
Octave graphics APIs. The M3 workflow needs a runtime reader to create IR from a
figure and LuaLaTeX plus PGFPlots/TikZ/`standalone` to compile the final PDF.
Python, `latexmk`, and PDF/raster tooling are not normal M3 export-runtime
dependencies.

## Reproducibility policy

Validation scripts accept tool commands as parameters and should default to
portable command names on `PATH`, not personal absolute paths. Exact validated
tool versions belong in run evidence and support documentation, not as invented
minimum-version claims.
