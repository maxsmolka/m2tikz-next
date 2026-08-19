# m2tikz-next M3.0 scientific export workflow report

## Executive Summary

M3.0 adds the first user-oriented `m2t.export` workflow on top of the validated
M2–M2.3 architecture. A supported figure can be analyzed, rendered, compiled
with LuaLaTeX, validated, and reported through one structured result without
changing the M2 IR or the inherited API.

## Public API

```matlab
result = m2t.export(figureHandle, outputBase);
result = m2t.export(figureHandle, outputBase, 'Overwrite', true);
```

`m2t` is the public pre-1.0 workflow namespace. `m2t2` remains the experimental
architecture namespace, and `matlab2tikz` remains the unchanged legacy API.

## ExportResult

The result contains `success`, `status`, `capability`, `texPath`, `pdfPath`,
`logPath`, `backend`, `compiler`, `diagnostics`, and stage timings. Status values
are `success`, `export_failed`, `compile_failed`, `validation_failed`, and
`unsupported`.

## Diagnostics

Diagnostics contain `severity`, `code`, `message`, and `stage`. Existing reader
identifiers such as `M2T2:E001:UnsupportedObject` are retained. Compiler
discovery and compilation failures have workflow codes, retain a failure log
when available, and surface the first meaningful TeX error.

## Capability Analysis

The workflow invokes `m2t2.reader.readFigure` once and validates the returned IR
before any output is written. Results are classified as `supported`,
`unsupported`, or `invalid`. There is no legacy fallback.

## Compiler Workflow

LuaLaTeX is discovered through `PATH` and executed only by the workflow layer.
Arguments are quoted by platform, line-break injection is rejected, output is
captured, and compilation occurs in an isolated temporary directory. The
renderer remains free of runtime handles and process execution.

## File Lifecycle

The requested base produces `.tex` and `.pdf` files. Compiler intermediates are
removed with the temporary build directory. A failed TeX run retains a
`.compile.log`. Existing workflow products are preserved unless the caller
explicitly supplies `Overwrite=true`.

## Tests

The M3 workflow suite covers line, scatter, errorbar, multiple axes, colorbar,
unsupported text, missing LuaLaTeX, invalid output paths, existing-output
policy, and deterministic repetition. Compiler-only tests cover known-good and
known-invalid TeX without requiring a figure.

## Cross-platform Validation

The complete workflow and compiler suites pass natively on Windows with GNU
Octave 11.3 and TeX Live 2026 and in Linux with GNU Octave 11.3, headless
gnuplot, LuaLaTeX, PGFPlots, and `standalone`. Relative, absolute, and
space-containing output paths are covered on both platforms. The Windows run
also verifies temporary writable LuaTeX cache provisioning and portable file
size/overwrite operations.

## CI

The three existing jobs remain. The `tex-preview` job derives a local image from
the exactly pinned Octave 11.3 image, adds the targeted LuaLaTeX dependencies,
and runs the M3 workflow and compiler tests after the existing curated preview
gate. The workflow passes `actionlint`; the derived image and M3 command pass in
the matching local Docker environment. A hosted run remains the post-push gate.

## Backward Compatibility

No M2 IR schema, M2 reader semantics, renderer semantics, or legacy
`matlab2tikz` behavior is changed. The new namespace delegates to the normalized
pipeline rather than replacing it.

## Remaining Gaps

M3.0 has no profile system, backend selection, heatmap/image path,
`tiledlayout`, `yyaxis`, polar, arbitrary annotation, or migrated 3-D support.
Native MATLAB validation and a native Windows LuaLaTeX rerun remain separate
validation items; no unsupported runtime range is broadened.

## Recommendation

1. Can a user export and compile a supported figure with one call? **Yes.**
2. Are failures machine-readable? **Yes.**
3. Are unsupported figures explicit? **Yes.**
4. Is compiler failure understandable? **Yes.**
5. Does the renderer remain handle-free? **Yes.**
6. Is the workflow cross-platform? **Yes; the complete integrated suite passes
   on native Windows and Linux.**
7. Is output deterministic? **Yes for the tested repeated export.**
8. Is the API small enough to evolve? **Yes.**
9. Can a publication profile be added without redesign? **Yes; it can extend
   workflow options while retaining result and diagnostic fields.**
10. Can future backend selection be added without redesign? **Yes; backend is
    already explicit in the result while M3.0 remains fixed to PGFPlots.**

**CONDITIONAL GO FOR M3.1** — proceed after the complete regression gate and
hosted M3 CI smoke are green; retain the current result and diagnostic model for
the future `Profile="publication"` option.
