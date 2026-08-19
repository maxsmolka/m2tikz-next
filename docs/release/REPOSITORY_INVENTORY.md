# M2.4A repository inventory

Captured before M2.4A modifications on 2026-08-09.

## M2.4B candidate-tip update

The final M2.4B candidate contains 230 files and no tracked `.audit` path. Its
source payload is approximately 1.2 MiB excluding Git metadata. The packed,
intentionally preserved Git history remains 51.16 MiB. See the root M2.4B
public-preview report for cleanup and validation results.

## Git state

- Branch: `release/open-source-preview`
- HEAD/tag: `f0be409`, `m2t-2.0-m2.3`
- Working tree: no tracked modifications; only `.audit/m2.1/`, `.audit/m2.2/`,
  and `.audit/m2.3/` were untracked
- Remote: `origin` fetched and pushed to
  `https://github.com/matlab2tikz/matlab2tikz.git`
- History: original matlab2tikz history followed by M0-M2.3 modernization
- Tags: inherited `0.x`/`1.x` tags plus `m2t-2.0-m1b`, `m2t-2.0-m2`, and
  `m2t-2.0-m2.3`

The intended future remote mapping is documented in `REPOSITORY_HISTORY.md`; no
remote was changed and nothing was pushed.

## Existing repository metadata

- License: `LICENSE.md`
- Authors/contributors: `AUTHORS.md`
- User documentation: `README.md`
- History/changelog: `CHANGELOG.md`
- Contribution guide: `CONTRIBUTING.md`
- CI: inherited `.travis.yml`
- Test entry point: `runtests.sh` plus MATLAB/Octave and PowerShell runners
- Installation/packaging: path-based `src/` installation documented in README;
  no modern package manifest or installer metadata was found
- IDE file: `matlab2tikz.sublime-project`
- Ignore files: root `.gitignore`, test/output and template-local ignores
- Documentation: ADR, design, validation, milestone report, and benchmark docs

At capture time there was no `NOTICE.md`, `SECURITY.md`, `CITATION.cff`, GitHub
workflow directory, or m2tikz-next release-policy directory. M2.4A adds policy
documents; citation metadata and modern CI remain M2.4B work.

## Generated and audit material

The repository contained 2,696 tracked files, of which 2,497 were below
`.audit/`. Generated tracked extensions included approximately:

| Extension | Tracked files |
|---|---:|
| PDF | 207 |
| log | 514 |
| aux | 232 |
| fdb_latexmk | 232 |
| fls | 232 |
| PNG | 119 |
| TeX | 440 |
| TSV | 393 |
| MAT | 1 |

These files originate primarily from M0/M1B/M2 validation and Golden-review
evidence. They were originally retained for traceability and manual review.
M2.4A therefore does not delete them blindly. Their public-tip reduction is a
reviewed publication blocker governed by `ARTIFACT_POLICY.md`.

Untracked M2.1-M2.3 compiler products numbered 1,817 files and are local outputs,
not curated source. M2.4A adds path-specific ignores for those directories
without deleting them.
