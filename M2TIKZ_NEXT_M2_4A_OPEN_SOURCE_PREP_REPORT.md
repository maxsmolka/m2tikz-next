# m2tikz-next M2.4A Open Source Preparation Report

## Executive Summary

M2.4A prepared the retained-history `matlab2tikz` repository for a future public preview under the independent project identity **m2tikz-next**. The work established licensing, attribution, history, artifact, support, versioning, dependency, divergence, security, and publication policies without changing the scientific export architecture or starting M3.

All required verification runs passed. Publication itself is not yet approved: legal/attribution questions, tracked generated evidence, a historical CI credential candidate, a private security contact, MATLAB validation, and M2.4B public-facing documentation and CI remain open.

## Repository Identity

- Public project name: `m2tikz-next`.
- Positioning: an independent modernization derived from `matlab2tikz`; it is not an official `matlab2tikz 2.0` release and is not presented as endorsed by the original maintainers.
- Short description: “A modern, validated scientific figure export pipeline derived from matlab2tikz.”
- Experimental namespace: `m2t2.*` remains unchanged for the preview-preparation phase and may receive a stable public name before 1.0.
- `m2t2.export(...)` is experimental. `matlab2tikz(...)` remains the legacy API and has not been redirected.

## Licensing

The inherited `LICENSE.md` contains a permissive two-clause BSD-style license with copyright `(c) 2008--2016 Nico Schlömer`. The existing license and source-file notices were preserved without reinterpretation or replacement. `src/private/m2tUpdater.m` contains an additional embedded notice for 2012--2014 Nico Schlömer.

`docs/release/LICENSE_AUDIT.md` records the evidence, redistribution conditions, retained notices, and matters requiring human review. In particular, `test/suites/private/herrorbar.m` contains third-party authorship and a MATLAB-derived-work statement without a nearby explicit license, while `logos/` has no separate licensing notice identified by this audit. These are legal-review items; this report makes no legal conclusion about them.

## Attribution

`NOTICE.md` now distinguishes the original `matlab2tikz` project and its authors/contributors from the `m2tikz-next` modernization. `AUTHORS.md` retains the inherited contributor list and now clarifies that historical attribution does not imply current maintainership or endorsement.

No original copyright notice was removed.

## Git History

The complete upstream history remains intact:

```text
upstream matlab2tikz history
-> modernization commits
-> m2tikz-next development
```

This is intentional for attribution, provenance, auditability, and traceability. The eight M0 through M2.3 development reports were moved with Git-aware renames from the repository root to `docs/development/`; their history was not discarded. No history rewrite or squash was performed.

At inventory time the branch was `release/open-source-preview`, `HEAD` was `f0be409`, and the architecture milestone tag was `m2t-2.0-m2.3`. Earlier milestone and inherited release tags remain development/provenance records.

## Remote Strategy

The current `origin` still points to `https://github.com/matlab2tikz/matlab2tikz.git` for fetch and push. M2.4A did not change remotes and performed no push.

The intended future mapping, after a separate `m2tikz-next` repository exists and publication is authorized, is:

```text
origin   -> user's m2tikz-next repository
upstream -> original matlab2tikz repository
```

`docs/release/REPOSITORY_HISTORY.md` documents this policy.

## Repository Hygiene

The initial inventory found 2,696 tracked files, including 2,497 tracked files below `.audit/`. Tracked generated extensions included PDFs, logs, LaTeX intermediates, PNGs, TeX files, TSV data, and one MAT file. Existing tracked evidence was not deleted blindly.

Path-specific `.gitignore` entries now ignore local generated output below:

- `.audit/m2.1/`
- `.audit/m2.2/`
- `.audit/m2.3/`

The local evidence remains on disk, but ordinary reruns no longer add untracked status noise. Broad `*.pdf` or `*.tex` rules were deliberately avoided because curated fixtures and examples may be source-controlled.

Machine-specific executable defaults in the M2/M2.1/M2.2/M2.3 validation and benchmark PowerShell launchers were replaced with portable command names such as `octave-cli`, `latexmk`, `pdftoppm`, `python`, and `bash`. No export behavior or architecture was changed.

## Artifact Policy

`docs/release/ARTIFACT_POLICY.md` separates durable public material—source, tests, benchmark source, ADRs, validation design, reports, and small deterministic fixtures—from local/generated compiler logs, PDFs, raster output, temporary TeX, and large benchmark products.

The 2,497 already tracked `.audit` files require a curated public-tip review in M2.4B. The policy favors removing inappropriate generated files from the future public tip while preserving Git history, unless later security review establishes a need for a targeted history rewrite.

## Support Matrix

`docs/SUPPORT.md` records the preview support boundary.

Validated baseline:

- GNU Octave 11.3
- TeX Live 2026
- PGFPlots 1.18.x
- LuaLaTeX
- pdfLaTeX, with documented Unicode limitations

Experimental architecture coverage includes line, scatter, errorbar, multiple axes, subplot-style and freeform layouts, manual positioning, overlays, colorbars, shared legends and labels in the IR/renderer, and JSON IR migration/replay.

MATLAB is explicitly **not yet validated** and no MATLAB support claim is made. Heatmaps, image rendering, `tiledlayout`, `yyaxis`, polar and 3D migration, M3 workflow, and backend selection were not added in M2.4A.

## Versioning

`docs/release/VERSIONING.md` recommends `v0.1.0-preview.1` as the first public preview version. Internal tags such as `m2t-2.0-m1b`, `m2t-2.0-m2`, and `m2t-2.0-m2.3` remain architecture-history tags rather than public semantic-release versions.

No public version tag was created.

## Dependency Inventory

`docs/release/DEPENDENCIES.md` classifies dependencies by role:

- Runtime/reader: GNU Octave; MATLAB is a future validation target, not a current support claim.
- Export/rendering: TeX Live, TikZ/PGF, PGFPlots, LuaLaTeX, and pdfLaTeX.
- Test/validation: Octave test runners, LaTeX compilation tools, Poppler utilities, Python utilities, and Pillow where used by visual checks.
- Development: shell and PowerShell orchestration used by repository workflows.

No unsupported minimum-version claim was invented. The validated baseline is recorded separately from general dependency identity.

## Secret / Personal Data Scan

The current-tree scan found no AWS, GitHub, Slack, private-key, or other common live-secret pattern after preparation. No plausible live credential was identified.

An inherited HipChat notification value in the old Travis configuration was classified conservatively as a likely expired or invalid historical credential candidate that still needs human review. It was removed from the current `.travis.yml`, but remains in preserved Git history. Its value is intentionally not reproduced in the new documentation.

Thirty tracked historical `.audit` files contained a local Windows user-profile
path. Four validation/benchmark scripts also contained absolute local tool
paths; those executable defaults were made portable. Historical upstream author
email addresses were retained where they serve attribution, changelog, updater,
or third-party provenance purposes.

No private/internal URL or machine-hostname issue was identified in the targeted current-tree scan. `docs/release/PUBLICATION_SCAN.md` records scope, classifications, limitations, and required follow-up without exposing credential material.

## Upstream Divergence

`docs/release/UPSTREAM_DIVERGENCE.md` summarizes the modernization at a high level: normalized and versioned IR, runtime-isolated reading, handle-free rendering, deterministic serialization, explicit diagnostics, mixed series, multiple-axes and layout foundations, figure-level elements, JSON migration/replay, visual validation, and performance work.

This is not a claim of full replacement coverage. Unsupported and unvalidated gaps remain explicit, including MATLAB validation and the deferred feature families listed in the support policy.

## Verification

Verification was run after the hygiene and portability changes:

| Check | Result |
|---|---|
| `git diff --check` | PASS |
| M2.3 validation | PASS — 29/29 compilation cases; 7 visual cases within page, no colorbar/axes overlap |
| M2.2 validation | PASS — 20/20 compilation cases; 10 geometry comparisons |
| M2.1 validation | PASS — 32/32 compilation cases |
| M2 validation | PASS — 20/20 compilation cases, executed through the M2.1 runner |
| Legacy smoke export/compile | PASS |
| Generated `.audit/m2.1`–`.audit/m2.3` status noise | PASS — ignored and absent from status |

The validation outputs were written below the ignored local `.audit` paths. Report moves did not break validation references. No scientific export source or API-routing change was made.

## Remaining Publication Blockers

Before a public preview can be published, M2.4B or an explicit review must address:

1. Human license/attribution review of `test/suites/private/herrorbar.m`, `logos/`, the inherited license wording, and the final `NOTICE.md`.
2. Human security review of the historical HipChat credential candidate and a decision whether history preservation is acceptable or targeted remediation is necessary.
3. Curated cleanup of the 2,497 tracked `.audit` files at the public tip, including 30 files containing a personal local path; historical evidence must not be removed indiscriminately.
4. A real private vulnerability-reporting contact or channel in `SECURITY.md`.
5. Polished public README, contribution/install guidance, `CITATION.cff`, and modern public CI.
6. Final packaging/install instructions and reproducible dependency setup.
7. MATLAB validation before any MATLAB compatibility claim.
8. Creation of the independent repository and the documented `origin`/`upstream` remapping only after explicit authorization.

These block publication, but they do not prevent the documentation and CI preparation planned for M2.4B.

## Recommendation

The repository has a coherent independent identity, preserved provenance, explicit policies, portable validation entry points, and a green Octave/TeX validation baseline. The unresolved items are concrete and bounded, but require human review and M2.4B work before any push or release.

**CONDITIONAL GO FOR M2.4B**
