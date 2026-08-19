# M3.5 Deterministic Backend Planner Report

## Executive Summary

M3.5 adds opt-in `ImageBackend='auto'` to `m2t.export` and `m2t.exportSet`.
Policy `default-v1` deterministically selects vector through 4096 cells and
hybrid above that boundary. Existing omitted, explicit vector, and explicit
hybrid behavior is unchanged. Planning is isolated from readers, profiles,
renderers, compilers, operating systems, and graphics toolkits.

## Motivation

M3.3/M3.4 measurements show a clear density crossover. Small vector matrices
retain useful TeX structure at acceptable cost, while 100x100 already becomes
noticeably expensive and 250x250 is impractical for routine compilation. The
planner makes the proven hybrid representation convenient without imposing it
on existing callers.

## Public API

Accepted values are `vector`, `hybrid`, and `auto`; the default is still
`vector`. Explicit requests always win. Auto is intentionally opt-in, and no
threshold or policy configuration was added to the public API.

## Planner Architecture

After supported FigureIR analysis and before profile transformation,
`m2t.planning.selectImageBackend` receives only normalized IR, requested mode,
and one normalized policy struct. It returns a decision; the existing render
plan executes only the selected `vector` or `hybrid` backend. `exportSet`
delegates each decision to `m2t.export`.

## Policy

`default-v1` has `version=1` and `maxVectorCells=4096`. A figure-level decision
uses the largest visible scalar image layer: `<=4096` selects vector and
`>4096` selects hybrid. No-image figures select vector. Multiple shapes with
the same cell count are equivalent. No runtime timing, trial compilation,
machine calibration, or publication-width signal is used.

## Threshold Evidence

4096 is the exact 64x64 boundary between measured points: 25x25 vector was
about 17 KB and 1.99 seconds of LuaLaTeX, while 100x100 vector was about 264 KB
and 9.96 seconds. At 250x250, vector reached 1.72 MB and 56.64 seconds versus
about 3.2 KB total and 1.41 seconds of hybrid compilation. The boundary is a
conservative pre-1.0 policy rather than a globally optimal cost claim.

## Reason Codes

Stable reasons are `explicit_vector`, `explicit_hybrid`,
`small_scalar_image`, `dense_scalar_image`, and `no_image_layer`. Normal auto
selection emits no warning or console noise.

## Result Metadata

`result.render.imageBackend` contains requested and selected values, reason,
complete policy metadata, visible image-layer count, and largest image cell
count. Existing `requestedImageBackend`, `effectiveImageBackend`, and `assets`
fields retain their meanings. Structured metadata reports `not_planned` with
an empty selection when unsupported analysis prevents a decision.

## exportSet Integration

Inheritance remains `entry override > set default > export default`. Entry
effective metadata records requested/selected backend, reason, and policy ID.
Explicit entry requests override a set-level auto request.

## Manifest Integration

Schema version remains 1. Each figure additively records
`requestedImageBackend`, `selectedImageBackend`, `backendReason`, and
`backendPolicy`; existing `imageBackend` records the selected representation.
No runtime handles, timing, or machine-specific data is serialized.

## Determinism

Repeated identical FigureIR, request, and policy values return identical
decision structs. The policy contains no OS, toolkit, runtime-handle, compiler,
PNG, display, or timing access. It is versioned independently of FigureIR,
manifest schema, and package version.

## Boundary Tests

P4-P6 establish `4095 -> vector`, `4096 -> vector`, and `4097 -> hybrid`.
Additional cases cover 2x2, 10x10, 25x25, 250x250, 500x500, and equal 10,000-
cell shapes 100x100, 50x200, 20x500, and 1x10000.

## Performance Evidence

| Size | Auto selection | Existing vector evidence | Existing hybrid evidence |
| --- | --- | --- | --- |
| 25x25 | vector | 17,171 B; 1.99 s compile | 1,268 B; 1.42 s compile |
| 100x100 | hybrid | 263,636 B; 9.96 s compile | 1,888 B; 1.44 s compile |
| 250x250 | hybrid | 1,722,125 B; 56.64 s compile | 3,228 B; 1.41 s compile |
| 500x500 | hybrid | intentionally not run | 5,665 B; 1.43 s compile |

The planner performs none of these measurements during export.

## Tests

P1-P24 cover explicit precedence, tiny/dense/boundary/rectangular inputs,
no-image, mixed and multiple-axes figures, profile independence, set defaults
and overrides, manifest/result metadata, deterministic repeats, unsupported
RGB/alpha preservation, invalid requests, policy validation, and architecture.
All M3.4 explicit backend tests remain intact. Hosted CI adds a compact 20x20
auto/vector plus 65x65 auto/hybrid compilation smoke.

## Cross-platform Results

Windows GNU Octave 11.3 local validation is green. The policy is runtime-, OS-,
and toolkit-independent by construction. Hosted Linux/gnuplot GNU Octave 11.3
execution requires the no-push external CI gate. MATLAB remains unvalidated.

## Hosted CI

The existing three jobs and pinned GNU Octave 11.3 toolchain remain. Repository
policy runs the planner invariant, and TeX preview runs the compact two-decision
smoke without compiling a large vector matrix.

## Backward Compatibility

Omitting `ImageBackend` still selects vector. Explicit vector and hybrid
requests never consult the threshold. Reader capability diagnostics, FigureIR,
rendering semantics, profiles, compiler behavior, and manifest schema meaning
remain unchanged. The full M2-M3.4 regression passed as the final local gate.

## Limitations

Policy v1 considers only the largest visible scalar image's cell count and
makes one figure-level decision. It does not estimate serialization bytes,
select per layer, plan non-image series, expose policy customization, or claim
global optimality. Existing image capability and hybrid-coordinate limitations
remain explicit.

## Recommendation

1. `ImageBackend='auto'` works through `m2t.export`: yes.
2. The default remains explicit vector behavior: yes.
3. Explicit vector and hybrid always override planning: yes.
4. The planner is deterministic: yes.
5. The planner is runtime/OS/toolkit independent: yes.
6. The threshold is justified by M3.3/M3.4 evidence: yes.
7. Threshold boundaries are tested: yes.
8. Rectangular matrices use total cell count consistently: yes.
9. Unsupported image semantics remain unsupported: yes.
10. Publication profiles remain independent of planning: yes.
11. `exportSet` supports auto defaults and explicit entry overrides: yes.
12. Manifests record requested/selected backend and reason: yes.
13. Structured planner metadata is explainable: yes.
14. Full M2-M3.4 local regression is green.
15. Windows is green; hosted Linux awaits external CI.
16. Preview readiness is conditional only on the no-push hosted gate.

CONDITIONAL GO FOR V0.2 PREVIEW
