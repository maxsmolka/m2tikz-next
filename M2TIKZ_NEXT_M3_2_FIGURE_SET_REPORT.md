# m2tikz-next M3.2 Figure Set Report

## Executive Summary

M3.2 adds one public operation, `m2t.exportSet`, for deterministic multi-figure
publication builds. It preflights an explicit struct array, resolves inherited
single-export settings, delegates every evaluated figure to `m2t.export`,
aggregates precise results, and writes portable manifest schema 1. Windows GNU
Octave 11.3 validation is green. The new hosted Linux smoke test is configured
but cannot run until the uncommitted branch is pushed.

## Public API

```matlab
result = m2t.exportSet(entries, outputDirectory, ...
    'Profile', 'publication', ...
    'Width', 'single-column', ...
    'Overwrite', true, ...
    'ContinueOnError', true);
```

This is the only new public operation. No project/configuration class, implicit
figure discovery, internal IR input, or filename derivation was introduced.

## Figure Set Specification

Entries are a nonempty struct vector with required lower-case fields `figure`
and `name`. Optional fields are limited to `profile`, `width`, and `overwrite`.
Names are explicit filename stems matching
`[A-Za-z0-9][A-Za-z0-9_-]*`; nested paths and traversal are rejected.
Caller-owned handles are neither closed nor mutated.

## Configuration Inheritance

Precedence is property-specific and deterministic:

```text
nonempty entry override > exportSet default > m2t.export default
```

The shared single-export option parser and shared profile/width selection layer
are used by both APIs. Every entry returns its effective profile, width, and
overwrite configuration for inspection.

## Pre-flight Validation

Before any figure export or product creation, preflight validates entry shape,
required and optional fields, options, effective profile combinations, output
directory, safe unique names, and known output collisions. Duplicate checks are
case-insensitive for cross-platform safety. Invalid specifications return
`invalid_set` and stable stage-`set` diagnostics without producing a partial
set.

## Export Aggregation

`exportSet` invokes `m2t.export` once per evaluated entry; it does not call the
reader, renderer, compiler, or PDF validator directly. Each aggregate entry
contains the original single `ExportResult` unchanged, plus its explicit name
and effective configuration. Summary categories—succeeded, failed,
unsupported, and skipped—are disjoint and sum to total.

Aggregate statuses are `success`, `partial_failure`, `failed`, and
`invalid_set`. Per-entry statuses and diagnostics retain their existing precise
identifiers.

## Continue-on-error Behavior

`ContinueOnError=true` is the default and evaluates later figures after an
unsupported or failed entry. With `false`, processing stops after the first
non-success and all remaining entries receive explicit `skipped` results with
`M2T:SET_SKIPPED_AFTER_FAILURE`. Successful earlier products remain; M3.2 does
not claim whole-set filesystem transactionality.

## Manifest

Every preflight-valid completed build writes `m2t-manifest.json` with:

- `schemaVersion: 1`;
- generator identity;
- normalized set defaults;
- ordered figure names and statuses;
- relative TeX/PDF filenames;
- effective profile and width.

Runtime handles, FigureIR, absolute paths, temporary directories, timestamps,
random IDs, and timings are excluded. Schema 1 is explicitly pre-1.0 and is
independent of FigureIR v2.

## Determinism

S12 confirms byte-identical manifests across repeated overwrite builds. S13
confirms byte-identical per-entry TeX. The manifest preserves entry order and
contains no intentionally nondeterministic values.

## Publication Example

`examples/07-publication-figure-set` builds four generic scientific figures:
analytic waves, uncertainty, samples, and a multi-panel comparison. One
reproducible `m2t.exportSet` call applies publication-profile
single-column defaults and a double-column override for the multi-panel figure.
All four TeX/PDF products and the manifest compile successfully locally.

## Tests

Windows GNU Octave 11.3.0 / TeX Live 2026 results:

- M3.2 S1-S16: **16/16 PASS**;
- hosted-CI-equivalent figure-set smoke: **3/3 figures PASS**;
- M3.1 profile suite: **13/13 PASS**;
- M3.0 workflow: **10/10 PASS**;
- compiler suite: **2/2 PASS**;
- M2 through M2.3 reader/renderer and fixture validation: **PASS**;
- curated examples and legacy smoke compilation: **PASS**;
- renderer, profile, and figure-set architecture invariants: **PASS**;
- documentation links and citation validation: **PASS**;
- `actionlint` 1.7.12 and `git diff --check`: **PASS**.

S1-S16 cover mixed supported figures, publication-profile inheritance, per-entry width
override, multiple axes, colorbar, duplicates, traversal, both continue modes,
collision preflight, deterministic manifest/TeX, paths with spaces,
`Profile='none'` compatibility, aggregate counts, and caller figure lifetime.

## Cross-platform Results

Windows GNU Octave 11.3.0 is fully green. Existing M3.1 hosted Linux/gnuplot
GNU Octave 11.3 is green. The M3.2 code has no OS/toolkit branches, and the new
three-figure hosted smoke uses the same pinned Octave image and TeX environment,
but its first run is pending because no commit or push was authorized.

## Hosted CI

The existing `repository-policy`, `octave-tests`, and `tex-preview` jobs remain.
Repository policy now checks that `exportSet` delegates to `m2t.export` and the
renderer is set-unaware. The TeX job adds one compact publication-profile set
with line, scatter, and errorbar entries, a double-column override, summary and
manifest assertions, and PDF existence checks. `actionlint` accepts the
workflow.

## Backward Compatibility

The extraction of the stable empty `ExportResult`, shared option parsing, and
profile selection leaves the public single-figure pipeline unchanged. M3.0 and
M3.1 suites are fully green, including byte-identical `Profile='none'`
behavior. FigureIR, renderer behavior, profile transformation, compiler,
scientific data, and legacy APIs were not changed.

## Limitations

M3.2 does not provide nested entry names, implicit discovery, configuration
files, atomic whole-set replacement, additional profiles, plot types, backends,
layouts, data reduction, or legacy fallback. Existing reader capability limits
remain explicit. Manifest schema and API remain pre-1.0. MATLAB and the new
hosted Linux smoke remain external evidence gates.

## Recommendation

1. Yes, multiple figures are exported with one `m2t.exportSet` call.
2. Yes, every evaluated entry reuses `m2t.export`; no parallel exporter exists.
3. Yes, set defaults and nonempty entry overrides have explicit deterministic
   precedence and returned effective metadata.
4. Yes, unsafe and case-insensitive duplicate names fail before output begins.
5. Yes, a failed/unsupported result remains precise while later entries can run.
6. Yes, both `ContinueOnError` modes and explicit skipped results are tested.
7. Yes, schema-1 JSON is machine-readable and byte-deterministic.
8. Yes, the publication profile works for complete sets and width overrides.
9. Windows is green; the configured M3.2 hosted Linux smoke awaits the first
   run on an unpushed branch.
10. Yes, M3.0 and M3.1 behavior and regressions remain green.
11. Yes, static checks confirm a handle-free, set-unaware renderer.
12. Yes, explicit scripts, safe output layout, overwrite policy, aggregate
    diagnostics, and the manifest make publication-directory rebuilds practical.

CONDITIONAL GO FOR M3.3
