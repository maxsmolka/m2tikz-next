# ADR-0007: Scientific export workflow and public namespace

- Status: Accepted for M3 development
- Date: 2026-08-11

## Context

The experimental `m2t2.export` entry point reads, renders, and writes TeX, but
end users must still discover the file, invoke a TeX engine, interpret process
status, locate logs, verify the PDF, and translate reader exceptions. That is a
useful architecture prototype rather than a complete scientific export
workflow.

Three API families also have different roles:

- `m2t` is the user-facing workflow namespace under active pre-1.0 development;
- `m2t2` contains the experimental reader, versioned IR, and handle-free
  renderer architecture;
- `matlab2tikz` remains the inherited legacy API with unchanged behavior.

Mechanically renaming `m2t2` would create churn without improving the workflow,
and silently redirecting the legacy API would hide coverage gaps.

## Decision

Introduce a small public orchestration layer:

```text
m2t.export
  -> m2t2 reader and IR validation
  -> handle-free PGFPlots renderer
  -> LuaLaTeX compiler abstraction
  -> dependency-free PDF validation
  -> structured ExportResult and diagnostics
```

The reader is called once. Its normalized IR is reused by the renderer, so the
analysis stage does not duplicate graphics semantics. Compilation remains
outside the renderer. M3.0 supports only LuaLaTeX and the PGFPlots backend.

The only initial name-value option is `Overwrite`, defaulting to `false`.
Compiler discovery uses `PATH`; compiler intermediates use a temporary build
directory. Failures are returned as structured results, and original `M2T2`
identifiers are preserved for analysis failures.

No API-stability promise is made before 1.0.

## Consequences

Benefits:

- one-call export and compilation for supported figures;
- machine-readable outcomes and clearer user diagnostics;
- explicit unsupported content without legacy fallback;
- deterministic TeX remains owned by the existing renderer;
- future profiles and backend planning can build on the result/diagnostic model;
- compiler products and intermediates have a defined lifecycle.

Costs:

- a new orchestration and process-execution layer;
- cross-platform quoting and compiler discovery responsibilities;
- temporary-directory and output-collision handling;
- additional compiler-backed tests and CI provisioning.

M3.0 deliberately does not introduce profiles, backend auto-selection,
heatmaps, `tiledlayout`, `yyaxis`, polar or 3-D support, or changes to the M2 IR.
