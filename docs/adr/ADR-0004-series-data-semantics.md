# ADR-0004: Series data semantics

- Status: Accepted
- Date: 2026-08-09
- Scope: line, scatter, and errorbar records in IR version 2

## Context

The M2 comparison exposed two differences: legacy output omits an empty line and
drops an infinite coordinate record, while M2 retains an empty series and turns
the non-finite record into a paired NaN gap. M2.1 must choose intentionally before
the same ambiguity spreads to scatter and errorbar.

## Decision

IR version 2 preserves every source series, including a series with zero records.
An empty series can still carry identity, visibility, style, and semantic naming;
dropping it in the reader would make legend and ordering behavior depend on data
cardinality. A renderer emits an empty plot operation, which has no geometry but
retains deterministic series structure.

Every record whose x or y coordinate is `NaN`, `+Inf`, or `-Inf` is normalized to
a paired `(NaN, NaN)` gap. The record remains in position, so the discontinuity
and record count are reproducible. `Inf` is not allowed past the reader because
PGFPlots/TeX handling can vary and an infinite Cartesian coordinate has no finite
plot position. Hand-built IR containing `Inf` or an unpaired NaN is invalid.

The same coordinate policy applies to line, scatter, and errorbar. Scatter draws
no marker for a gap. For errorbar, all four error extents at a gap become NaN.
At a finite base point, error extents must be finite and non-negative; missing or
infinite uncertainty is diagnosed instead of silently removing the observation.

No downsampling, decimation, or record removal occurs in this policy.

## Rationale

Preserving object and record identity is stronger for scientific traceability and
mixed-series ordering than reproducing an exporter-specific omission. A paired
gap matches plot topology: adjacent line segments must not bridge a non-finite
record, while scatter/errorbar simply have no drawable position. Canonicalization
also makes JSON replay and renderer behavior independent of MATLAB/Octave storage
details.

Octave 11.3 behavior and compiled PGFPlots output are covered by M2.1 tests.
Equivalent MATLAB Handle Graphics behavior is **MATLAB VALIDATION REQUIRED**;
this decision is the 2.0 normalized contract even if runtime source objects expose
non-finite data differently.

## Consequences

M2.1 intentionally remains different from legacy for empty lines and infinite
coordinates. Semantic comparison must report those differences rather than call
them regressions. All series readers share one coordinate normalizer, validators
enforce paired gaps, and future backends must implement the same record-preserving
policy.
