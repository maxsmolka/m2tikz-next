# M7.0 - Public API freeze candidate

## Baseline

Clean public main `0615c1be3f1c3d55ff547dee21299b4fea80ab54`, after M6.8
PR #12. Exact head `067e9816de0d92ab23441c4097944f848de0a68e` passed
repository-policy, octave-tests and tex-preview in run 35088166756.
Merge ancestry, fast-forward and local/remote milestone-branch cleanup were
verified before starting `m7.0/public-api-freeze-candidate`.
The preceding full portable and native M6.8 gates are the recorded baseline.

## Audit and decision

[API.md](docs/API.md) defines the two public workflows and their options,
case/type/default rules, profiles, image decisions, complete result shapes,
diagnostic/status contract, set inheritance, manifest schema and filesystem
lifecycle. Helpers in m2t2 and m2t internal/profile/planning are not public API.

No breaking change, alias or new public option is necessary. The existing
surface becomes the 1.0 freeze candidate; subsequent breaking changes are
exceptional and need an ADR, migration notes and one canonical replacement.
Additive fields must preserve meaning; callers should tolerate new fields.
Diagnostic codes/stages/statuses, not prose, are stable automation keys.

The audit explicitly records often-missed existing behavior: extensions are
appended; paths are not existence guarantees; planning failures can have a
supported capability; early profile/planner metadata is not an applied result;
overwrite is not atomic rollback; manifest failure can coexist with every
entry succeeding; entry summary counts exclude manifest errors. No change to
scientific output, source ownership, security or precision was made.

Stale scatter/profile stability statements, obsolete workflow-version wording,
logPath wording and set aggregation descriptions are corrected. The inherited
diagnostics proposal is labeled historical, not current omission policy.
README, architecture/status/roadmap, workflow/profile/set documentation and
the validation matrix link to the candidate. Documentation link checking now
covers the required contemporary contract documents, not just README/support.

## Validation

Validated with MATLAB R2026a Update 4 on Windows.

That historical statement is retained. New evidence: native MATLAB R2026a
Update 5 on Windows and GNU Octave 11.3 each pass eight real compiler-backed
API cases. MATLAB uses a temporary bridge to Linux LuaLaTeX / TeX Live
2025/Debian; this is not a native Windows TeX installation claim.

Cases cover defaults/result fields, invalid options, product collisions,
170 mm publication width/case/last-option rules, RGB auto versus forced-vector
failure, set inheritance/manifest fields, duplicate-name preflight and
unsupported/skipped outcomes. They assert unchanged source IR. Existing
security/compiler suites retain detailed lower-level failure coverage.
No new graphics or visual-parity claim is introduced; rendering is unchanged.

Full portable regression passed (140 core, 235 extended, eight curated PDFs,
all accumulated foundation/TeX suites and eight new API checks), with final
validation marker and process exit zero. Six architecture invariants,
expanded documentation links, staged confidentiality, citation 0.5.0,
actionlint and whitespace checks pass. All three exact-head hosted checks
and mergeability remain mandatory before
merge. Release/citation stay 0.5.0, with no tag or release creation.
M7.1 starts only after verified merge and branch cleanup.
