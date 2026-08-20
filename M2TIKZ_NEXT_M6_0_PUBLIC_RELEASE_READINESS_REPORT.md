# m2tikz-next M6.0 Public Release Readiness Report

## Executive Summary

The repository is technically ready for an M6.0 release-readiness pull request.
The public documentation now presents m2tikz-next as a modern, validated
scientific figure export pipeline derived from matlab2tikz, with `m2t.export`
and `m2t.exportSet` as the public workflow and `m2t2.*` as internal/experimental
implementation interfaces.

The working release target is 0.5.0. The portable regression set passed 266/266
structured cases, examples 01–10 passed, all six curated preview documents
compiled with LuaLaTeX, and repository-policy checks passed. No product source,
runtime behavior, public function signature, remote, tag, or release was
changed.

Final release publication remains gated by the bounded human and hosted checks
listed below. No commit was created by this work.

## Public Product Identity

The visitor-facing description is:

> A modern, validated scientific figure export pipeline derived from
> matlab2tikz.

README, NOTICE, citation metadata, and release policy clearly preserve upstream
provenance without claiming official upstream status. Historical engineering
headings that used a misleading product name were neutralized. The inherited
`matlab2tikz(...)` API remains a separate legacy path.

## Version Target

`CITATION.cff` is the existing machine-readable version source and now records
`0.5.0`. No duplicate runtime version constant was introduced. The changelog
and versioning policy use the same working target, and no tag or release was
created.

Version 0.5.0 is defined as a usable scientific-export preview/beta with a
functional broad core workflow, known unsupported graphics, and no pre-1.0 API
stability promise.

## README Review

The first screen now explains product purpose, upstream relationship, exact
MATLAB/Octave validation boundaries, TeX expectations, the installation link,
and a runnable `m2t.export` example. Later sections cover installation,
single-figure and figure-set APIs, publication profiles, supported families,
image backends, deterministic diagnostics, limitations, examples, contribution,
security, attribution, and license.

Milestone chronology is no longer the primary navigation model.

## Installation Review

`docs/INSTALLATION.md` now separates MATLAB, GNU Octave, and TeX requirements.
It documents source checkout, `src` path setup, LuaLaTeX, TikZ/PGF, PGFPlots,
the standalone class, optional validation tools, platform boundaries, a minimal
end-to-end export, and the location and overwrite policy of generated products.

The MATLAB statement remains exact: validated with MATLAB R2026a Update 4 on
Windows. GNU Octave 11.3 is the hosted Linux CI runtime.

## Support Matrix Review

`docs/SUPPORT.md` now uses four classifications: Supported, Supported with
limitations, Experimental, and Unsupported. It covers the current 2-D,
layout, image, annotation, grouped-bar, boxplot, Line3, surface, and Patch3
boundaries without broadening narrow capabilities.

Per-point scatter behavior, tiled layouts, dual axes, polar plots, broad
annotation/bar/boxchart/patch families, general 3-D scenes, perspective and
lighting/material semantics, broad transparency, and general downsampling
remain visible limitations. MATLAB/Octave runtime differences and the exact
MATLAB evidence remain linked from the matrix.

## Public API Review

`m2t.export`, `m2t.exportSet`, and `Profile='publication'` are consistently
documented and were resolved directly in GNU Octave 11.3. The minimal examples
use the actual extension-free output-base convention. End-user documentation no
longer recommends `m2t2.export`; references to `m2t2.*` identify internal
architecture or retained engineering evidence.

No API signature, routing, option, diagnostic, IR schema, or semantics changed.

## Documentation Navigation

README provides direct paths to Installation, Support, Profiles, Figure Sets,
Image Backends, Workflow, Contributing, and Security. A scan of all 81 tracked
Markdown files found no missing local Markdown link.

## Changelog

`CHANGELOG.md` now contains an unreleased 0.5.0 target organized as Added,
Changed, Validation, and Known limitations. It summarizes user-visible public
capabilities without recreating internal development chronology.

## Versioning Policy

`docs/release/VERSIONING.md` now defines a SemVer-based pre-1.0 policy: `0.x`
may change, minor versions represent meaningful feature milestones, and patch
versions represent compatible fixes within the current minor contract. Release,
IR, manifest, and internal namespace versions remain independent.

## Release Artifact Policy

The artifact policy now specifies source-first GitHub releases. Reviewed source,
license and attribution, documentation, tests, examples, and small required
fixtures are eligible. Local build directories, restricted validation inputs,
licensed runtime material, tool caches, compiler intermediates, and unnecessary
generated output are excluded.

Dependency documentation now records the exact MATLAB and hosted Octave
boundaries and separates normal export dependencies from validation-only tools.

## GitHub Metadata

- `CITATION.cff` records m2tikz-next version 0.5.0 and the current repository.
- The original matlab2tikz repository remains a separate referenced software
  entry.
- NOTICE preserves upstream license and contributor provenance and disclaims
  official upstream status.
- CONTRIBUTING distinguishes public workflow from internal architecture and
  states the exact MATLAB boundary.
- SECURITY defines a non-public reporting route and a 0.5.x support policy.
- The bug form no longer labels MATLAB as unvalidated.
- The required CI job identifiers remain `repository-policy`, `octave-tests`,
  and `tex-preview`.

The inherited license text and contributor record remain unchanged.

## Confidentiality Regression

`test/checkConfidentiality.ps1` passed. Additional tracked-filename and
tracked-text scans found no restricted research-specific terminology, local
user-home paths, internal repository identifier, restricted validation-corpus
identifier, or historical restricted branch identifier. No sensitive search
denylist was added to the repository.

Repository remotes were not modified.

## CI Review

The three required jobs remain intact:

- `repository-policy`: whitespace, six architecture invariants, documentation,
  confidentiality, citation, and Actionlint;
- `octave-tests`: pinned GNU Octave 11.3.0, M2–M2.3, smoke generation, M3/M4
  preparation, and runtime-neutral M5 IR lanes;
- `tex-preview`: pinned GNU Octave 11.3.0, LuaLaTeX/PGFPlots provisioning,
  curated preview compilation, and public M3 workflow smoke tests.

Actionlint 1.7.7 was added to repository policy without renaming jobs. Local
Actionlint validation passed.

## Portable Regression

GNU Octave 11.3.0 on Windows produced the following result:

| Group | Passed | Failed |
| --- | ---: | ---: |
| M2–M2.3 reader/renderer suites | 88 | 0 |
| M3 workflow and compiler | 12 | 0 |
| Publication profile workflow | 13 | 0 |
| Figure sets | 16 | 0 |
| Scalar images | 18 | 0 |
| Hybrid images | 24 | 0 |
| Backend planner | 24 | 0 |
| MATLAB-validation preparation | 12 | 0 |
| M5.1 annotation IR | 9 | 0 |
| M5.2 grouped-bar IR/runtime-neutral lane | 10 | 0 |
| M5.3 boxplot IR | 10 | 0 |
| M5.4 narrow 3-D IR | 10 | 0 |
| Calibrated publication-profile acceptance | 20 | 0 |
| **Total** | **266** | **0** |

All six architecture invariants passed. Examples 01–10 passed. The four full
runtime-native M5.1–M5.4 suites are documented as licensed-MATLAB lanes and were
not counted as portable Octave tests; the existing MATLAB R2026a Update 4 on
Windows evidence was not rerun or generalized.

## TeX Preview

The consolidated public validator passed with TeX Live 2026 and LuaLaTeX. The
five curated modern examples and the legacy smoke document compiled 6/6. Public
workflow examples 06–10 also completed all their requested PDF exports,
including publication widths, a four-figure set, vector/hybrid heatmaps, and
automatic image-backend selection.

## git diff --check

PASS. Modified text files have no trailing whitespace or patch whitespace
errors.

## Files Changed

- Public entry documents: README, CHANGELOG, CONTRIBUTING, NOTICE, SECURITY,
  CITATION, and one issue form.
- User documentation: Installation, Support, Workflow, MATLAB validation
  matrix, examples navigation, and the MATLAB validation plan.
- Release documentation: artifact, dependency, upstream-divergence, and
  versioning policies.
- CI and validation: workflow Actionlint gate and citation validator.
- Retained engineering evidence: product-name headings only.
- This M6.0 readiness report.

## Product Source Impact

None. No file under `src/` changed and no renderer, reader, IR, planner,
compiler, or profile behavior changed.

## Public API Impact

None. The work clarifies the already-existing public API and updates release
metadata; it does not add, remove, or change a callable API.

## Remaining Release Blockers

1. Obtain final human approval of the exact license identification, NOTICE
   wording, and retained third-party review decision.
2. Enable or verify GitHub Private Vulnerability Reporting before publishing
   the release.
3. Observe green `repository-policy`, `octave-tests`, and `tex-preview` jobs on
   the reviewed pull request before tagging `v0.5.0`.

These gates do not require product changes and do not block review of this
release-readiness branch.

## Recommended Next Step

Review this documentation-only diff in an M6.0 pull request. After the three
bounded release gates above are complete, perform one clean hosted run, approve
the `v0.5.0` tag, and create a source-first release in a separate authorized
step.

## Completion Questions

1. First-time-user understanding: **YES**.
2. End-to-end installation documentation: **YES**.
3. Minimal export example: **YES**.
4. `m2t.export` is clearly primary: **YES**.
5. `m2t.exportSet` is documented: **YES**.
6. `Profile='publication'` is consistent: **YES**.
7. `m2t2.*` internals are separated: **YES**.
8. Upstream attribution is preserved: **YES**.
9. Independent/non-official status is clear: **YES**.
10. MATLAB statement is precise: **YES**.
11. Octave support is accurate: **YES**.
12. TeX toolchain is correct: **YES**.
13. Feature boundaries are classified: **YES**.
14. Known limitations are visible: **YES**.
15. Incomplete scientific output is treated as a risk: **YES**.
16. Changelog suits the public project: **YES**.
17. The 0.5.0 target is coherent: **YES**.
18. SemVer pre-1.0 policy is documented: **YES**.
19. Artifact policy excludes local/restricted material: **YES**.
20. GitHub metadata/templates are public-ready: **YES, subject to the reporting-channel check**.
21. Confidentiality regression passes: **YES**.
22. Restricted research/history identifiers are absent: **YES**.
23. Examples 01–10 pass: **YES, 10/10**.
24. Portable regressions pass: **YES, 266/266**.
25. TeX preview passes: **YES, 6/6**.
26. Documentation validation passes: **YES**.
27. Citation validation passes: **YES, version 0.5.0**.
28. YAML/Actionlint passes: **YES**.
29. `git diff --check` passes: **YES**.
30. Working tree is ready for a release-readiness PR: **YES, uncommitted as requested**.
31. Product semantics changed: **NO**.
32. Public API changed: **NO**.
33. Release blockers remain: **YES, the three bounded gates above**.

## Completion Decision

CONDITIONAL – RELEASE READINESS BLOCKERS REMAIN
