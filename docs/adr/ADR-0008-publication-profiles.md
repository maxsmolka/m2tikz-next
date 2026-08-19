# ADR-0008: Publication profiles

- Status: Accepted for M3.1 development
- Date: 2026-08-11

## Context

Figures used in scientific publications need consistent physical dimensions and
typography without changing scientific content. Mutating runtime graphics
objects would make output depend on MATLAB/Octave state, while renderer-specific
flags would scatter policy across serialization code.

## Decision

Use a data-driven, deterministic profile transformation after normalized IR
creation and before rendering:

```text
runtime figure -> reader -> FigureIR -> profile transform
               -> transformed FigureIR + render configuration -> renderer
```

Profile lookup and policy live in `m2t.profile`. The publication transform
changes FigureIR physical size while preserving all other IR fields, and emits
generic typography and standalone-page settings consumed by the renderer. The
reader remains profile-unaware, the transform uses no graphics handles, and the
renderer remains profile-name-unaware and handle-free.

M3.1 provides `none` and `publication`, with
85 mm and 170 mm width presets.
Source aspect ratio is preserved within documented bounds. Since the current
reader cannot reliably distinguish author-set values from runtime defaults,
line and marker styling is preserved.

## Consequences

- publication dimensions and typography are repeatable;
- scientific data and semantic settings remain unchanged;
- runtime handles are never mutated for presentation;
- future profiles reuse the transform/configuration boundary;
- an additional validated transformation layer and result metadata are needed;
- output appearance is intentionally not pixel-identical to the default profile.

## Rejected alternatives

- Mutating MATLAB/Octave figures couples publication behavior to runtime state.
- Hard-coding publication values in renderer functions prevents reusable
  profiles and violates separation of policy and serialization.
- Shell or TeX-template post-processing obscures diagnostics and determinism.
- One-off renderer flags do not form an extensible profile model.
