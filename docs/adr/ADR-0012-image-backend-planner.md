# ADR-0012: Deterministic scalar-image backend planner

## Status

Accepted for M3.5.

## Context

M3.3 and M3.4 established a strong representation crossover. A 25x25 vector
matrix remains practical, 100x100 is noticeably expensive, and 250x250 reached
about 1.72 MB of TeX and 56.6 seconds of LuaLaTeX time. The corresponding
250x250 hybrid export used about 1 KB of TeX, a 2.2 KB PNG, and 1.4 seconds of
compilation. Explicit selection remains useful, but repetitive scientific
workflows benefit from an explainable opt-in policy.

## Decision

Add `ImageBackend='auto'` without changing the `vector` default. A dedicated,
handle-free planner receives validated FigureIR and policy `default-v1`:

```text
name: default
version: 1
maxVectorCells: 4096
comparison: <= vector, > hybrid
```

4096 is the 64x64 boundary between the measured inexpensive 25x25 case and the
already costly 100x100 case. It is a conservative pre-1.0 policy, not a claim of
global optimality. The only signal is the largest visible scalar image's total
cell count. This figure-level choice fits the existing single-backend render
plan and avoids premature per-layer configuration. Rectangular shapes with the
same cell count receive the same decision.

Explicit `vector` and `hybrid` requests bypass the threshold. Auto without a
visible image selects vector. Stable reasons are `explicit_vector`,
`explicit_hybrid`, `small_scalar_image`, `dense_scalar_image`, and
`no_image_layer`. The decision and policy are additive result metadata.
`exportSet` delegates planning to `m2t.export`; schema-1 manifests add requested,
selected, reason, and policy fields. Publication profiles do not affect cell
count or selection.

Capability analysis remains before planning, so unsupported scientific
semantics cannot be hidden by selecting hybrid. The renderer only executes the
selected backend and contains no threshold logic.

## Consequences

Auto decisions are reproducible across OS, toolkit, and machine speed. Policy
versioning makes a future threshold change explainable without tying it to the
FigureIR, manifest, or package version. Users retain complete control through
the two explicit backend values. The internal policy can accept future
normalized signals without expanding the M3.5 public API.

## Rejected alternatives

- hidden automatic behavior for existing calls;
- runtime benchmarking, compile-and-retry, or adaptive calibration;
- hardware-, OS-, toolkit-, or publication-width-dependent heuristics;
- a random or changing threshold;
- forcing hybrid globally;
- full-figure rasterization or automatic data reduction;
- public threshold, policy, or cost-model options in M3.5.
