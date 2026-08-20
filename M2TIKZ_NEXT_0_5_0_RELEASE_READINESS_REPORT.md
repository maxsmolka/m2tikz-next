# m2tikz-next 0.5.0 Release Readiness Report

## Executive Summary

The release-facing repository state is technically clean for a `release/0.5.0`
pull request. Version 0.5.0 is consistently presented as the first public
pre-1.0 preview/beta, the user-facing changelog is finalized, concise GitHub
release notes are available, and the public API and evidence boundaries remain
unchanged.

The exact README quick start passed. The portable release validation passed
266/266 structured cases, examples 01–10 passed, the legacy smoke export passed,
and six curated TeX previews compiled. No product source, public API, CI job
identifier, remote, tag, commit, or release was changed or created.

Repository review found no obvious technical or provenance-based release
blocker. Final human approval of the inherited license identification,
attribution wording, and two retained upstream test references remains required;
this report does not make a legal determination.

## Release Identity

- Project: `m2tikz-next`
- Description: A modern, validated scientific figure export pipeline derived
  from matlab2tikz.
- Release: `0.5.0`
- Future tag after merge and approval: `v0.5.0`
- Maturity: public pre-1.0 preview/beta

m2tikz-next is independent from the original matlab2tikz project. It preserves
upstream history, license, notices, and contributor attribution without claiming
official upstream status.

## Version Consistency

`CITATION.cff` remains the canonical machine-readable version source and records
`0.5.0`. Release-facing references now agree:

- README: version 0.5.0 public preview/beta;
- CHANGELOG: `[0.5.0]`, with no Unreleased marker or date;
- SECURITY: current `0.5.x` preview line and version 0.5.0 maturity;
- versioning policy: release `0.5.0`, future tag `v0.5.0`;
- workflow documentation and release notes: version 0.5.0.

Retained milestone reports contain historical version targets as evidence of
their original state. They are not current release metadata and are not linked
as the release source of truth. No redundant runtime version constant was added.

## Changelog Review

`CHANGELOG.md` now has a final `[0.5.0]` section organized as Added, Changed,
Validation, and Known limitations. It describes public capabilities and support
boundaries rather than internal milestone chronology. No release date was added
because repository policy does not require one and the release has not yet been
created.

## Release Notes

`docs/release/RELEASE_NOTES_0_5_0.md` is suitable as the basis for the future
GitHub Release description. It includes highlights, installation, quick start,
supported areas, known limitations, validation, exact runtime boundaries,
upstream relationship, security reporting, and compatibility guidance.

## Quick Start Verification

The README code using `addpath('src')`, a 200-point sine wave, and
`m2t.export(gcf, 'figure')` passed under GNU Octave 11.3.0 with the documented
TeX Live 2026 toolchain. It produced nonempty `figure.tex` and `figure.pdf`.
Generated products were moved below ignored `.audit/release-0.5.0/` paths.

An environment preflight also confirmed that Windows path order matters when
multiple TeX distributions are installed. Installation documentation now tells
users to verify that `where lualatex` and `lualatex --version` select the
intended initialized installation.

## License Review

The inherited `LICENSE.md` exact text is unchanged. It retains the original
2008–2016 copyright notice and redistribution conditions. The separately
embedded notice in `src/private/m2tUpdater.m` is also unchanged. The release
continues to identify the exact root text as authoritative and commonly
classified as BSD-2-Clause without offering a legal guarantee.

No obvious release blocker was found in the repository license review. Human
confirmation of the license identification and final attribution presentation
remains required.

## NOTICE Review

NOTICE identifies m2tikz-next as an independent modernization derived from
matlab2tikz, preserves the original copyright and contributor references, and
does not recast upstream contributors as m2tikz-next maintainers or endorsers.
No NOTICE edit was objectively required in this finalization pass. Its final
wording remains a human-approval item.

## Third-Party Review

Tracked material was classified as follows:

- **Inherited upstream:** legacy exporter, helpers, tests, checksum references,
  root license, attribution, and retained Git history.
- **Project-authored:** modern `m2t.*`/`m2t2.*` implementation, validation
  harnesses, documentation, CI, and synthetic examples.
- **Generated synthetic fixture:** `test/fixtures/ir/line-v1.json`, retained as
  a deterministic schema-migration input.
- **External dependency/reference:** MATLAB, GNU Octave, TikZ/PGF, PGFPlots,
  TeX Live, Poppler, Python validation libraries, and Actionlint are referenced
  but not vendored.

The previously reviewed unlicensed helper and logo are absent from the current
tree. No tracked image, executable, archive, MATLAB runtime, or third-party
binary is present. Two included inherited test sources remain explicit human
review items: `test/private/calculateMD5Hash.m` credits a DataHash approach, and
`test/suites/ACID.m` cites/adapts public MathWorks examples. Repository history
preserves their upstream provenance, but repository-local text does not
independently establish their exact reuse boundary.

## Security Readiness

SECURITY now directly instructs users to use GitHub Private Vulnerability
Reporting and describes 0.5.x as the current preview line. The user confirmed
that Private Vulnerability Reporting is enabled. This review did not
programmatically inspect the GitHub setting; the repository wording is
compatible with the confirmed configuration.

## Artifact Policy

The release remains source-first. GitHub-generated source archives are
sufficient. The policy excludes local builds, restricted validation inputs,
temporary output, MATLAB runtime/license material, generated tests, caches, and
ignored `.audit/`/`build/` directories. `.gitignore` and the artifact policy are
consistent; no manual archive was created.

## Confidentiality Regression

`test/checkConfidentiality.ps1` passed. Additional scans of tracked filenames
and textual content found no restricted research terminology, internal
repository identifier, restricted development branch identifier, absolute
user-home path, or restricted validation identifier. No sensitive denylist was
added to the repository.

## Public API Audit

Release documentation consistently presents `m2t.export`, `m2t.exportSet`, and
`Profile='publication'` as public interfaces. `m2t2.*`, FigureIR, JSON, and
manifest schemas remain internal/experimental. Historical architecture reports
that discuss the former prototype entry point are retained evidence, not
end-user guidance.

## Support Boundary

Release notes remain within `docs/SUPPORT.md`. Constant-style scatter, grouped
vertical numeric bars, traditional vertical boxplots, annotations, and narrow
orthographic 3-D support are described with explicit limits. Per-point scatter,
tiled layouts, dual axes, polar plots, general 3-D scenes, broad transparency,
general downsampling, and broad bar/boxchart/patch families remain visibly
unsupported or non-general.

## MATLAB / Octave Validation Boundary

The exact MATLAB statement is preserved: validated with MATLAB R2026a Update 4
on Windows. No other MATLAB release or platform is implied. GNU Octave 11.3 is
the hosted Linux CI baseline and the local portable validation runtime.

## Portable Regression

GNU Octave 11.3.0 produced the following release result:

| Group | Passed | Failed |
| --- | ---: | ---: |
| M2–M2.3 readers/renderers | 88 | 0 |
| M3 workflow/compiler | 12 | 0 |
| Publication-profile workflow | 13 | 0 |
| Figure sets | 16 | 0 |
| Scalar images | 18 | 0 |
| Hybrid images | 24 | 0 |
| Backend planner | 24 | 0 |
| MATLAB-validation preparation | 12 | 0 |
| M5.1 annotation IR | 9 | 0 |
| M5.2 grouped-bar portable lane | 10 | 0 |
| M5.3 boxplot IR | 10 | 0 |
| M5.4 narrow 3-D IR | 10 | 0 |
| Publication-profile acceptance | 20 | 0 |
| **Total** | **266** | **0** |

Examples 01–10 passed. MATLAB-only runtime-native M5 lanes were not substituted
for their documented portable IR lanes; existing MATLAB R2026a Update 4 evidence
was not generalized.

## TeX Preview

The consolidated validator compiled the five curated modern previews and the
legacy smoke document: 6/6 PASS. Examples 06–10 also completed their requested
LuaLaTeX products, including publication widths, a four-figure set, vector and
hybrid images, and automatic backend selection.

## CI Readiness

The required job identifiers remain unchanged: `repository-policy`,
`octave-tests`, and `tex-preview`. Local equivalents passed, including all six
architecture invariants, documentation links, confidentiality, citation
metadata, and Actionlint 1.7.7. Hosted jobs must be observed after the pull
request is opened; CI was not redesigned on the release branch.

## git diff --check

PASS. Changed text files contain one final newline, no trailing whitespace, and
no extra blank line at EOF.

## Files Changed

- `AUTHORS.md`: clarify inherited upstream-maintainer wording.
- `CHANGELOG.md`: finalize the 0.5.0 entry.
- `README.md`: change target wording to release wording and link release notes.
- `SECURITY.md`: align instructions with enabled private reporting.
- `docs/INSTALLATION.md`: document TeX path selection on Windows.
- `docs/WORKFLOW.md`: change target wording to release wording.
- `docs/release/VERSIONING.md`: finalize 0.5.0 and future `v0.5.0` tag policy.
- `docs/release/LICENSE_AUDIT.md` and `THIRD_PARTY_REVIEW.md`: record the 0.5.0
  provenance review and bounded human-review items.
- `docs/release/RELEASE_NOTES_0_5_0.md`: new public release notes.
- this release-readiness report.

## Product Source Impact

None. No file under `src/` changed.

## Public API Impact

None. No function signature, option, behavior, diagnostic, schema, or routing
changed.

## Human Review Checklist

| Item | Status | Evidence/action |
| --- | --- | --- |
| 1. Inherited LICENSE unchanged | YES | `LICENSE.md` and embedded updater notice have no diff. |
| 2. Upstream attribution present | YES | README, NOTICE, AUTHORS, CITATION, and Git history. |
| 3. NOTICE wording appropriate | REVIEW NEEDED | Repository review found no obvious issue; approve final wording. |
| 4. AUTHORS wording appropriate | REVIEW NEEDED | Upstream record preserved; present-tense ambiguity corrected. |
| 5. CITATION metadata correct | YES | Validator passes; version/repositories/license are present. |
| 6. Third-party material accounted for | REVIEW NEEDED | Removed items and two included inherited references are documented. |
| 7. Dependency documentation accurate | YES | Runtime and validation-only roles remain separated. |
| 8. Project independence clear | YES | No official-status or endorsement claim. |
| 9. SECURITY matches private reporting | YES | Wording aligns with the user-confirmed enabled mechanism. |
| 10. No restricted/local material | YES | Automated and targeted scans pass. |
| 11. Source-first artifact policy clear | YES | GitHub source archives are sufficient; generated/local output excluded. |
| 12. Version 0.5.0 consistent | YES | All current release-facing sources agree. |
| 13. Release notes accurate | YES | Capabilities and boundaries match support documentation. |
| 14. Known limitations visible | YES | README, CHANGELOG, support matrix, and release notes. |
| 15. Product semantics unchanged | YES | No `src/` diff and full portable validation passes. |

## Remaining Release Blockers

No technical repository blocker was found. The following approvals remain:

1. Human confirmation of the inherited license identification.
2. Human approval of final NOTICE and AUTHORS wording.
3. Human disposition of the two documented inherited external references.
4. Green hosted `repository-policy`, `octave-tests`, and `tex-preview` checks on
   the release pull request.

## Recommended Release Procedure

1. Review this release-only diff and complete the human checklist.
2. Open the `release/0.5.0` pull request without creating a tag.
3. Require all three hosted jobs to pass and resolve any review comments.
4. Merge the approved pull request into `public/main`.
5. Confirm the merged commit still reports version 0.5.0 and has a clean tree.
6. Create `v0.5.0` from the approved merged commit.
7. Create the GitHub release from the release notes and use GitHub-generated
   source archives; do not attach local validation/build products.

The `v0.5.0` tag must not be created before the pull request is merged.

## Completion Questions

1. Is 0.5.0 consistently represented? **YES**.
2. Is CHANGELOG ready for release? **YES**.
3. Are release notes ready for GitHub? **YES**.
4. Does the README quick start still work? **YES**.
5. Is `m2t.export` the documented primary API? **YES**.
6. Is `m2t.exportSet` documented? **YES**.
7. Is `Profile='publication'` consistent? **YES**.
8. Is `m2t2.*` kept internal/experimental? **YES**.
9. Is upstream attribution preserved? **YES**.
10. Is project independence explicit? **YES**.
11. Was inherited license text preserved? **YES**.
12. Is NOTICE ready for human approval? **YES; approval remains required**.
13. Is the third-party inventory coherent? **YES; two references require human review**.
14. Are dependencies documented accurately? **YES**.
15. Does SECURITY align with private vulnerability reporting? **YES**.
16. Are release artifacts source-first and public-safe? **YES**.
17. Does confidentiality regression pass? **YES**.
18. Are restricted historical/private terms absent? **YES**.
19. Is the support boundary accurately represented? **YES**.
20. Is the exact MATLAB validation statement preserved? **YES**.
21. Is Octave validation represented accurately? **YES**.
22. Do all portable regressions pass? **YES, 266/266**.
23. Do examples 01–10 pass? **YES, 10/10**.
24. Does TeX preview pass? **YES, 6/6**.
25. Do architecture invariants pass? **YES, 6/6**.
26. Does documentation validation pass? **YES**.
27. Does citation validation pass? **YES, version 0.5.0**.
28. Does YAML/Actionlint pass? **YES**.
29. Does `git diff --check` pass? **YES**.
30. Were any product source files changed? **NO**.
31. Was any public API changed? **NO**.
32. Is the branch ready for a `release/0.5.0` PR? **YES, subject to human review**.
33. Which items still require human approval? **License identification,
    NOTICE/AUTHORS wording, and the two inherited external references**.
34. Should `v0.5.0` be tagged before the PR is merged? **NO**.

## Completion Decision

CONDITIONAL – HUMAN RELEASE REVIEW REQUIRED
