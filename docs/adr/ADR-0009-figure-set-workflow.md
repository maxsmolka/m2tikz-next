# ADR-0009: Figure-set workflow

- Status: Accepted for M3.2 development
- Date: 2026-08-11

## Context

Scientific publications contain many figures that should be rebuilt with one
consistent, reproducible export policy. Requiring users to invoke
`m2t.export` manually for every figure provides no aggregate diagnostics,
continue-on-error behavior, collision preflight, or machine-readable inventory.

## Decision

Add one public orchestration operation, `m2t.exportSet`. It accepts an explicit
struct array of figure handles and safe names, resolves set defaults plus a
small per-entry override surface, validates the complete set before output,
calls `m2t.export` once per evaluated entry, aggregates the unchanged
single-export results, and writes deterministic manifest schema 1.

The critical boundary is that `exportSet` is not a second exporter. It does not
read FigureIR, call the reader, render TeX, or invoke LuaLaTeX directly. The
existing single-figure workflow remains authoritative for analysis, profile
transformation, serialization, compilation, validation, and overwrite behavior.
The renderer remains handle-free and unaware of figure sets and manifests.

## Consequences

Benefits:

- reproducible multi-figure publication builds through one public call;
- explicit inheritance and per-entry effective configuration;
- preflight rejection of unsafe/duplicate names and known collisions;
- aggregate status, summary, timings, and continue-on-error diagnostics;
- deterministic, portable build metadata without runtime handles.

Costs:

- additional orchestration, validation, aggregation, and manifest schema;
- successful earlier products remain when a later entry fails;
- callers must explicitly retain and supply every figure handle and name.

## Rejected alternatives

- A copy/pasted batch exporter would create two competing pipelines.
- Shell scripts are useful automation but not a portable public MATLAB/Octave API.
- Discovering all open figures risks exporting debug/helper windows.
- Legacy fallback would hide modern-reader support boundaries.
- Whole-set filesystem transactions add staging/replacement complexity outside
  the M3.2 scope.
