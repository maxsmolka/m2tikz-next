# 0.8.0 feature-freeze readiness report

## Scope and baseline

Baseline: merged M7.3 commit `5902ca0c39833d79ce3092e2e1c2aedfcb4e2eda`.
This phase prepares a feature-freeze candidate; it neither tags nor releases
0.8.0. Latest published version and CITATION remain 0.5.0.

## Freeze and support review

The new release policy allows correctness, diagnostic, compatibility,
portability, performance-regression, documentation, security and release work.
New major graphics families before 1.0 require a critical real acceptance gap
that cannot reasonably be deferred. Speculative features and unrelated API
expansion are not authorized. Public APIs remain `m2t.export` and `m2t.exportSet`;
breaking changes require exceptional justification, an ADR and migration notes.
FigureIR v2 and manifest schema 1 remain separate version domains.

README, status, roadmap, changelog, support, FigureIR, dependency and versioning
statements were reconciled with runtime/environment contracts. Draft 0.8.0
notes distinguish development from released functionality. Documentation checks
now cover the new freeze/draft notes and release dependency/versioning links.
No product implementation, options, schemas, graphics families or CI gate was
changed. Historical release/milestone evidence is not relabeled as new evidence.

## Evidence boundary

Validated with MATLAB R2026a Update 4 on Windows.

That is the retained historical statement. This phase's fresh native tests use
R2026a Update 5 on Windows, as explicitly approved, and Octave 11.3 on Linux.
Native MATLAB invokes real Linux LuaLaTeX through a local compiler bridge;
this is not native Windows TeX evidence. Portable fixtures do not establish
native support for unavailable runtime objects or another MATLAB release.
Compilation does not replace external scientific visual review.

## Acceptance gates

- Full portable acceptance passed: Public Preview 140 core cases and eight
  curated PDFs, all extended suites, rich-scatter/image TeX, S1, M6.3-M6.8,
  M7.0 API, M7.1 canonical replay/nine PDFs, M7.2 fifteen compatibility cases
  with real compilation and M7.3 twelve compiler-backed environment cases.
- Fresh native MATLAB acceptance passed: M7.2 15/15, M7.3 12/12, S1 security,
  M6.8 determinism 8/8, M7.0 API 8/8 and M7.1 FigureIR 18/18. Actual compiled
  PDFs and public profile/set workflows are included, not compiler stubs.
- All six architecture invariants, documentation links, citation metadata,
  actionlint/YAML, staged confidentiality and whitespace checks passed.
- Existing M7.2/M7.3 synthetic visual review remains applicable: this phase
  changes no product code or graphics fixtures. Real external visual/semantic
  acceptance is still outstanding, not inferred from compilation success.
- Hosted `repository-policy`, `octave-tests` and `tex-preview` are mandatory
  on the exact PR head before merge; their integration evidence is recorded
  separately rather than claiming future CI success in this commit.

## Release and remaining work

Source-first artifact, attribution and security policies are unchanged.
No tag, release, remote change, broad push, private fixture or actual external
tester content is part of this phase. Separate authorization is required to
finalize release metadata, tag or publish 0.8.0.

Next: generic local external acceptance package, 5-10 critical real figures on
another MATLAB version, feedback triage, M8.0 readiness, v0.9.0 / v1.0.0-rc.1,
M8.1 burn-in and v1.0.0. Known support, precision, process-timeout and environment
boundaries remain explicit in the linked contracts.

## Decision

READY FOR 0.8.0 FEATURE-FREEZE RELEASE REVIEW
