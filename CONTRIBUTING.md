# Contributing to m2tikz-next

Thank you for helping improve the preview. Keep changes focused, reproducible,
and explicit about unsupported behavior.

## Architecture

The public workflow is exposed through `m2t.export` and `m2t.exportSet`. Its
implementation is split into runtime readers, normalized/versioned IR, and a
deterministic PGFPlots renderer. The `m2t2.*` namespace contains internal and
experimental interfaces, not recommended end-user entry points.

Two rules are non-negotiable:

- Runtime-specific behavior belongs in readers.
- Renderers must not access MATLAB/Octave graphics handles.

Represent information in the IR rather than passing a graphics object across
that boundary. Unsupported runtime properties must produce stable, explicit
diagnostics; do not silently discard scientific data.

## Tests and fixtures

Run the public gate from PowerShell:

```powershell
./test/runPublicPreviewValidation.ps1
```

For the complete local validation matrices, run `test/runM23Validation.ps1`,
`test/runM22Validation.ps1`, and `test/runM21Validation.ps1`; the M2.1 runner
also executes the M2 line prototype validation.

When adding a fixture:

1. keep its plotting input minimal and deterministic;
2. assert normalized IR semantics separately from rendered text;
3. add a figure-free renderer case where appropriate;
4. compile representative standalone TeX with LuaLaTeX;
5. retain only source and small required reference input, not `.audit/` output.

## Style and diagnostics

- Follow the surrounding MATLAB/Octave style and use stable `M2T2:*` diagnostic
  identifiers for user-visible failures.
- Keep serialization deterministic and avoid locale- or machine-specific paths.
- Do not add broad generated-file ignores that hide curated fixtures.
- Run `git diff --check` before submitting.

## Pull requests

Describe the user-visible behavior, tests, documentation changes, IR/schema
impact, and any compatibility risk. Keep unrelated refactors separate. Confirm
that the renderer remains handle-free and runtime logic remains reader-side.

The current MATLAB boundary is MATLAB R2026a Update 4 on Windows. Every change
touching graphics objects, properties, layout, or diagnostics must document its
MATLAB-validation implications and update the validation plan when the gate
changes. An Octave pass alone is not a MATLAB support claim, and the recorded
MATLAB run does not generalize to other releases or platforms.

The inherited contributor guide remains available through Git history for
historical project workflow context; it does not define the m2tikz-next process.
