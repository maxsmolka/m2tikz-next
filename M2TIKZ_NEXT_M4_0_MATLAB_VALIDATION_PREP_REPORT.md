# M4.0 MATLAB Validation Preparation Report

## Executive Summary

M4.0 prepares an executable, privacy-safe MATLAB validation program without
requiring or claiming MATLAB support. A single future `matlab -batch` command
detects the exact runtime, audits HG objects, runs 26 semantic fixtures through
reader/IR/renderer/workflow/TeX evidence, checks caller state, and writes JSON
and Markdown reports. Product source and public APIs are unchanged.

## Current Support Baseline

`v0.2.0-preview.1` remains validated with GNU Octave 11.3 on Windows and hosted
Linux, LuaLaTeX, and PGFPlots 1.18.x. The complete pre-change M3.0-M3.5 baseline
passed. MATLAB compatibility remains pending and is scoped eventually to the
specific detected trial release, not all MATLAB versions.

## MATLAB Validation Strategy

The program is layered L0-L11: environment, HG audit, normalized semantics,
renderer determinism, TeX compilation, public workflow, profile, figure sets,
images, hybrid, planner, and separately reported legacy smoke. MATLAB and
Octave trees may differ; scientific FigureIR semantics are the compatibility
contract. Fixes in M4.1 follow evidence categories A-E rather than speculation.

## Runtime Detection

`m2t_test.runtimeInfo` reports runtime kind, version, release, OS, architecture,
Octave toolkit where applicable, and installed product names/versions. It does
not query licenses, accounts, usernames, hostnames, serial numbers, Java
identity, or machine IDs. Recursive sanitization removes workspace, temporary,
and user-home paths from reports.

## Dependency Audit

Traced modern paths are designed for base MATLAB. No optional toolbox call was
found. Hybrid PNG output uses `imwrite`, whose actual trial availability is an
L0 check rather than an inferred license query. External requirements are
LuaLaTeX, TikZ, `standalone`, and PGFPlots; selected development geometry checks
may use Poppler. Details are in `docs/MATLAB_DEPENDENCIES.md`.

## Fixture Registry

One executable registry defines F01-F26, covering lines, scatter, errorbars,
mixed series, legends/ticks/axes, manual and multiple axes, colorbars, shared
elements where constructible, scalar images, profile, sets, hybrid, and auto.
Every definition records capabilities, expected support, visual-review flag,
and comparison mode. Generic closed-form data avoids proprietary or personal
inputs.

## Graphics Object Audit

The HG audit captures classes, parent/child classes, visibility, tags, series
data/style, mapping/alpha/color, axes limits/ticks/directions, placement,
legend/colorbar location, and text. It omits handle IDs, memory addresses,
timestamps, and raw paths. Curated JSON snapshots are generated locally and
remain evidence artifacts rather than committed raw dumps.

## IR Comparison

The comparator distinguishes exact equality, field-specific numeric
equivalence, declared runtime representation differences, and semantic
mismatches. Scientific data/colors use `1e-12`; normalized geometry uses
`1e-8`; text, kinds, order, and discrete fields are exact. Raw HG trees are
never required to match.

## Validation Layers

Stable development categories are ENV, HG, READER, IR, RENDER, TEX, WORKFLOW,
PROFILE, SET, IMAGE, HYBRID, PLANNER, and LEGACY. Missing external tools are
environment evidence, not MATLAB product failures. Capability failures retain
reader diagnostics and can be separated from IR, rendering, workflow, and
compilation failures.

## Report Model

Schema-1 `report.json` contains sanitized runtime/environment evidence, fixture
results, layer results, legacy status, and summary. `report.md` presents the
same auditable evidence. Per-fixture directories retain normalized IR, TeX,
PDF, assets, manifests, and logs without embedding machine-specific roots in
the report.

## Trial Execution Plan

`docs/MATLAB_TRIAL_EXECUTION_PLAN.md` defines the activation gate and a focused
five-day sequence: L0/HG, reader/IR comparison, workflow/TeX/PDF, images/hybrid/
planner, then evidence-based triage and V01-V08 review. The first command is:

```powershell
matlab -batch "addpath('test'); result=runMatlabValidation; assert(result.success)"
```

## Support Criteria

A release-specific claim requires all modern core fixtures, public workflow,
profile, sets, images, hybrid, planner, TeX/PDF, determinism, mutation checks,
and manual visual subset to pass with no unresolved semantic mismatch. Existing
unsupported capabilities need not become supported.

## Legacy Separation

Legacy `matlab2tikz(...)` receives its own L11 smoke status. A legacy-only
failure is visible but does not automatically invalidate a modern `m2t` claim
unless it contradicts an explicit compatibility commitment.

## CI Strategy

Lane A remains public GNU Octave 11.3 hosted CI and now runs the MATLAB
preparation tests without MATLAB. Lane B is local licensed MATLAB validation.
No GitHub-hosted MATLAB availability or license is assumed; MathWorks Actions
integration remains future work.

## Tests

MP1-MP12 pass under GNU Octave without MATLAB. They validate sanitizer/privacy,
registry completeness and unique IDs, L0-L11 completeness, exact/tolerant/
expected-difference comparison, path removal, JSON schema, Markdown generation,
pending support truthfulness, and architecture isolation. The shared harness
also completed all 26 fixtures under Octave with 26 passes, no environment
failures, and no semantic mismatch.

## Regression Results

The pre-change and post-change M3.0-M3.5 suites are green. M2-M2.3, public
preview, examples 01-10, legacy smoke, and the shared 26-fixture Octave harness
also pass. Architecture, documentation, citation, workflow syntax, and
whitespace checks passed as the final local gate.

## Remaining Risks

No real MATLAB HG2 data exists yet. Current-release object representation,
headless behavior, PNG encoding determinism, default geometry, and TeX
differences remain evidence questions for M4.1. The harness may expose fixture
construction differences that require capability-based test adaptation before
product changes are justified.

## Trial Activation Decision

All preparation checklist items are implemented and the final post-change
Octave regression is green. The trial may be activated; that decision does not
imply MATLAB compatibility.

## Recommendation

1. One non-interactive MATLAB command is prepared: yes.
2. Runtime/version evidence is collected automatically: yes.
3. Machine, license, and private fields are sanitized or excluded: yes.
4. F01-F26 cover current M2-M3.5 capabilities: yes.
5. MATLAB/Octave comparison is semantic, not raw-handle based: yes.
6. Reader/IR/render/workflow failures are distinguishable: yes.
7. Image, hybrid, planner, profile, and figure-set behavior is covered: yes.
8. Legacy status is separate from modern claims: yes.
9. PDF compilation is validation evidence: yes.
10. V01-V08 define the manual visual subset: yes.
11. Matrix rows trace to fixture IDs: yes.
12. Reports exclude machine-specific noise: yes.
13. The complete current Octave baseline is green before and after changes.
14. M4.0 makes no speculative MATLAB product change: yes.
15. A precise trial-day plan exists: yes.
16. The repository is ready for trial activation: yes.

READY TO ACTIVATE MATLAB TRIAL
