# m2tikz-next M2.4B Public Preview Report

## Executive Summary

M2.4B produced a staged public-preview candidate for the independent
`m2tikz-next` project without starting M3, changing remotes, creating a tag, or
publishing anything. The candidate replaces inherited visitor-facing material,
removes generated and provenance-uncertain content from the current tip, adds
portable examples and CI, and passes both the complete local regression matrix
and an index-exact clean-copy validation.

Starting state on `release/open-source-preview` was `f0be409` tagged
`m2t-2.0-m2.3`, with the M2.4A working changes present, clean staged/unstaged
diff checks, unchanged upstream `origin`, 2,696 tracked files, and 2,497 tracked
files below `.audit/`. The packed retained history measured 51.16 MiB.

## Third-Party Review

`test/suites/private/herrorbar.m` was an inherited legacy-test helper with
external attribution but no explicit redistribution license in repository
evidence. No source, test entry point, or script referenced it. It was removed
from the current tip without replacement or history rewrite.

The inherited `logos/matlab2tikz.svg` had no separate asset-license or provenance
notice and no current reference. The complete `logos/` directory was removed
from the current tip. The README remains text-only.

The inherited `LICENSE.md`, original copyright notices, `AUTHORS.md`, and Git
history remain intact. `docs/release/THIRD_PARTY_REVIEW.md` records the evidence
and conservative decisions.

## Historical Security Review

The old HipChat CI notification finding was inherited from upstream, was not
introduced by m2tikz-next, is absent from the current tree, and has no repository
evidence of current use. No current-tree live-token pattern was found. Upstream
history remains intentionally preserved for provenance.

Formal disposition in `docs/release/SECURITY_REVIEW.md`:

**ACCEPT PRESERVED UPSTREAM HISTORY**

No credential value was reproduced and no history rewrite was performed.

## Audit Cleanup

All 2,497 tracked `.audit` paths were removed from the candidate tip with normal
Git deletion. They consisted primarily of generated TeX, PDFs, rasters, compiler
logs, LaTeX intermediates, timing tables, and machine-local evidence.

The clean-state validation exposed one genuine test dependency: a small,
deterministic version-1 JSON migration fixture. It was preserved as
`test/fixtures/ir/line-v1.json`, and the renderer test, ADR, and MATLAB validation
plan now use that source-controlled fixture path. No test consumes `.audit` as
input. Two non-generated M0 audit and performance harnesses were separately
retained under `benchmarks/`. Durable milestone summaries remain in
`docs/development/`, and `.audit/` is ignored as a whole.

The final staged candidate contains 230 files and zero tracked `.audit` paths.

## Repository Size

Before cleanup, the checked-out evidence directories occupied hundreds of
megabytes locally. The final current-tip source payload is approximately 1.2 MiB,
excluding `.git` and generated validation output.

`git count-objects -vH` after cleanup reports 51.16 MiB in packs plus 110.75 KiB
of loose objects. The retained historical artifacts therefore make clone history
unusually large relative to the current source tree, but not severe enough to
override the provenance policy in M2.4B. Final publication review should accept
this approximately 51 MiB history cost explicitly; no size-driven history
rewrite was performed.

## README / Documentation

`README.md` is now a concise public landing page covering motivation, evidence-
backed features, quick start, support boundary, experimental API, legacy API,
limitations, installation, validation, roadmap, attribution, contribution,
security, and licensing.

It prominently states that MATLAB compatibility is not yet validated and does
not claim full replacement coverage. Public identity consistently distinguishes
`m2tikz-next` from historical `matlab2tikz`, while provenance documents retain
the original name where appropriate. `CHANGELOG.md` now summarizes user-visible
preview development rather than duplicating the complete inherited changelog.

## Installation

`docs/INSTALLATION.md` describes a source-checkout workflow with Windows-first
validated guidance and PATH-based commands for Git, GNU Octave, LuaLaTeX, and
PGFPlots discovery. It does not invent a package-manager, Octave Forge, MATLAB
toolbox, or registry release. The future repository URL remains an explicit
placeholder until repository creation is authorized.

## Examples

Five source-only examples were added: line, scatter, asymmetric errorbar,
multiple axes with different scales, and an axes-owned colorbar. All regenerate
standalone TeX below ignored output paths. All five ran successfully in GNU
Octave 11.3 and compiled with LuaLaTeX. No generated example output is tracked.

## Contribution Workflow

`CONTRIBUTING.md` documents repository architecture, test entry points, fixture
rules, IR boundaries, explicit diagnostics, style expectations, pull-request
scope, and MATLAB-validation implications. Runtime-specific behavior belongs in
readers, and renderers must not access MATLAB/Octave graphics handles.

GitHub bug and feature forms request reproducible synthetic cases and relevant
environment versions without asking users to upload private research data. The
pull-request template covers tests, documentation, diagnostics, architecture,
whitespace, and MATLAB implications.

## Security Reporting

`SECURITY.md` identifies GitHub Private Vulnerability Reporting as the intended
channel without claiming that it exists yet. Enabling and verifying that feature
before public announcement is an explicit release checklist item. No personal
email address was introduced as a security contact.

## Citation

`CITATION.cff` prepares version `0.1.0-preview.1`, identifies the artifact as
software, uses collective contributor wording rather than claiming sole
authorship, and records original-project provenance. The checked-in validator
verifies syntax and required identity fields; CI installs PyYAML for full YAML
parsing. The top-level `repository-code` identifies the current m2tikz-next
repository, while the referenced software entry retains the original matlab2tikz
upstream URL.

## CI

`.github/workflows/ci.yml` defines three public-service-free jobs:

- repository policy: changed-file whitespace, renderer invariant, documentation
  links, and citation validation;
- Octave tests: M2 through M2.3 reader/renderer tests, semantic fixtures,
  examples, and smoke generation without a MATLAB license;
- TeX preview: curated example and legacy-smoke generation plus LuaLaTeX
  compilation.

The CI uses public Linux packages and PATH-based commands. It does not normalize
the historical missing-Golden ACID status into a false pass or upload hundreds
of generated artifacts. Hosted execution remains to be observed after creation.

## Public Preview Validation

`test/runPublicPreviewValidation.ps1` performs environment discovery, M2 through
M2.3 reader/renderer suites, semantic fixtures, five example exports, a legacy
smoke export, six LuaLaTeX compilations, the handle-free invariant, documentation
links, citation validation, publication scans, and `git diff --check` when Git
metadata is present.

The complete local public-preview run passed with GNU Octave 11.3, TeX Live
2026/LuaLaTeX, and Python 3.12.13. Existing final matrices also passed:

| Gate | Result |
|---|---|
| M2.3 | PASS — 29/29 compilation cases; 7 geometry cases inside page with no colorbar/axes overlap |
| M2.2 | PASS — 20/20 compilation cases; 10 visual geometry pairs |
| M2.1 | PASS — 32/32 compilation cases; 16 visual pairs |
| M2 | PASS — 20/20 compilation cases; 10 informational visual comparisons |
| Legacy smoke | PASS — generated and LuaLaTeX-compiled by the public-preview gate |
| Renderer invariant | PASS |
| Documentation links | PASS |
| Citation validation | PASS |
| `git diff --check` | PASS |

A broken local Poppler wrapper was encountered during one attempted visual run;
rerunning with the actual discovered `pdftoppm` executable completed all
matrices. This was a tool-wrapper issue, not a product failure.

## Fresh-Clone Validation

The definitive clean-state test exported the fully staged candidate directly
from the Git index with `git checkout-index`. It contained exactly 230 files,
with no `.git`, `.audit`, ignored test output, local absolute executable path, or
other untracked developer file.

From that index-exact copy, the complete public-preview validator passed all
core suites, semantic fixture generation, five examples, legacy smoke, six
LuaLaTeX compilations, and all policy scans. The temporary copy was deleted.
This confirms no dependency on historical `.audit` output or hidden local files.

## Current-Tree Publication Scan

The final targeted current-tree scan found no common live-token pattern,
private-key material, personal local machine path in publication-owned files,
private/internal/local-service URL, tracked `.audit` file, or current HipChat
notification configuration. Historical upstream author contact information
remains only where it is attribution/provenance data.

## Remaining Publication Blockers

Before public announcement or a first tag:

1. Obtain final human approval of the exact-text license identification,
   `NOTICE.md`, and the conservative third-party removal decisions.
2. Use `https://github.com/maxsmolka/m2tikz-next` as the configured independent
   repository URL and review the intended `origin`/`upstream` mapping before any
   push.
3. Enable and verify GitHub Private Vulnerability Reporting.
4. Observe all GitHub Actions jobs and resolve any hosted Linux difference.
5. Perform final human publication approval, then create
   `v0.1.0-preview.1`; no tag or release exists yet.
6. Accept the approximately 51 MiB preserved-history clone cost explicitly.

MATLAB validation remains mandatory before any MATLAB compatibility claim, but
does not block creation of an accurately labeled Octave preview repository.

## Recommendation

The staged candidate is technically reproducible, legally conservative at the
current tip, operationally prepared for public CI, and free of identified
current-tree publication data. Repository creation is appropriate once the
bounded human and URL/security setup conditions above are followed; public
announcement and tagging remain separately gated.

**CONDITIONAL GO FOR PUBLIC REPOSITORY CREATION**
