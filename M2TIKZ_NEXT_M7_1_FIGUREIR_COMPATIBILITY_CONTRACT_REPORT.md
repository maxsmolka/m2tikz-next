# M7.1 - FigureIR compatibility contract

## Baseline and scope

Clean public main `ebe716dabab4e03f7a8e0bb4185dcb34c02ca407`, after M7.0
PR #13. Exact final head `3b58d8be0c89051685d09bde1304459249107e76`
passed all three required jobs in run 35090587140. Its earlier hosted failure
was a test-only relative-path expectation, corrected and rerun in both runtimes;
the final full local regression also passed before merge. Merge ancestry,
fast-forward, branch removal locally/remotely and clean tree were verified.
This phase uses `m7.1/figureir-compatibility-contract`; release remains 0.5.0.

## Compatibility decision

[FIGURE_IR.md](docs/FIGURE_IR.md) and
[ADR-0025](docs/adr/ADR-0025-figureir-compatibility-contract.md) define v2
backward readability, optional defaults, missing/unknown fields, required
payload/ownership, order, schema bumps, migration and JSON precision.
Pre/post rich scatter and image, fixed tiled layout, dual Y, broader 3-D and
optional background/bar bounds are explicitly covered. Plans, diagnostics,
profile results and manifests are separate from scientific IR.

No schema bump: no supported scientific meaning/type/ownership is changed.
Loader hardening enforces the prior documented required-field boundary rather
than inventing missing coordinates or owners. v1 migration only accepts its
known line schema, not arbitrary kinds coerced to lines. The existing generated
series-ID default is documented as a narrow legacy normalization exception.
Unknown v2 fields remain opaque optional metadata; unknown kinds fail. Future
versions fail explicitly. Provided scatter colors survive old mode defaults.

## Serialization findings and correction

Both native JSON runtimes decode bare scalar null as empty data: raw encoding
of a single NaN coordinate therefore silently erased that point. The observed
Octave encoder also serialized realmin as zero and realmax as an unrelated
integer. Tests exposed both problems before acceptance; assertions were not
weakened to excuse them.

Internal `m2t2.ir.toJson` now writes validated/normalized lexical-key JSON with
ordered arrays, explicit numeric dimensions, 17-digit doubles and unambiguous
`[null]` for scalar NaN. The loader rejects ambiguous bare null. Existing
unambiguous supported v1/v2 JSON remains readable. Ambiguous old data requires
source-based recovery, not guessed migration; guidance is documented.
Raw runtime jsonencode is not the archival contract.

The stricter annotation check exposed another pre-existing Octave issue:
jsondecode renamed ArrowIR `end` to `xEnd`, allowing constructor endpoints
to mask missing decoded semantics. Field-name rewriting is now disabled in
that codec adapter, nonportable keys fail explicitly, and nondefault arrow
endpoints plus complete annotation owner/payload fields are checked. Existing
annotation roundtrips are retained, not removed to make the gate pass.

This helper is internal, not a new end-user API. It is not on the public export
path: TeX retains 15 digits, PNG its existing channel precision, and manifests
schema 1. No new graphics family, raster fallback, reduced data, public option,
timing threshold or unmeasured serialization performance claim is introduced.

## Evidence

Validated with MATLAB R2026a Update 4 on Windows.

That historical evidence is retained. New native codec execution uses MATLAB
R2026a Update 5 on Windows; portable/runtime checks use Octave 11.3. Real native
compilation uses a temporary bridge to Linux LuaLaTeX / TeX Live 2025/Debian.

- Nine committed synthetic input/canonical JSON pairs cover old/rich scatter,
  old/rich image-alpha, tiled, dual, 3-D, bar/background and NaN line gaps.
- Eighteen focused cases pass in both runtimes: exact normalized semantic
  equality, repeated/canonical/key-permuted bytes, complete render-plan equality,
  unchanged v1 fixture migration, missing/unknown fields, versions, ownership,
  double edges, scalar NaN/empty distinctions, singleton RGB/alpha shapes and
  escaped JSON-like text. Nine canonical outputs match across observed runtimes.
- Nine real PDFs compile in each runtime with independent relative PNG assets.
  All nine native PDFs were visually inspected. Rich point roles, image alpha,
  grid order, separate dual scales and bar bounds are retained. The line-gap
  case correctly has no invented connection between isolated unmarked points;
  known 3-D viewport/tick proximity is not a new pixel-parity claim.
- Thirteen existing/new portable IR/renderer suites also pass when executed
  under native MATLAB, separately from native graphics-family support claims.
- Final full portable regression passes: 140 core, 235 extended, eight curated
  PDFs, accumulated foundation/TeX suites, eight API checks and the 18-plus-nine
  FigureIR checks; final marker and process exit zero. Final native regression
  and nine compiles also pass with exit zero after the ArrowIR correction.
  Reviewed native TeX products are byte-unchanged in the final run.
- Six architecture invariants, expanded documentation links, staged
  confidentiality, citation 0.5.0, actionlint and whitespace checks pass.
  Exact-head repository-policy, octave-tests and tex-preview plus mergeability
  remain mandatory before merge.

Architecture/status/roadmap and current documentation are aligned through
M7.1, with only the requested M7.2-and-later roadmap remaining. No M7.2 work,
tag or release is included. The final master report follows verified M7.1
integration, phase-branch cleanup and clean-tree checks.
