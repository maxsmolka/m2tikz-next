# Post-M6.2 status and documentation alignment

## Scope and baseline

Phase A starts at public/main commit
74f1d42f0d051f4e8bafde01736b62eb87585f39, with functionality through M6.2
and latest release v0.5.0. This phase changes documentation only.

## Changes

- Added an Unreleased changelog section for M6.1/M6.2. Released 0.5.0 text is
  preserved as a historical snapshot, with an explicit boundary note.
- Updated workflow documentation for rich scatter, scalar direct mapping,
  RGB/image alpha, forced-vector diagnostics, planning stages, and asset lifecycle.
- Replaced historical test guidance with the current layered validation model,
  exact runner commands, separate native/portable/TeX evidence, and an explicitly
  historical legacy section. Travis/Jenkins are not current operational guidance.
- Added ARCHITECTURE.md, PROJECT_STATUS.md and ROADMAP.md and linked them from
  README. The roadmap follows S1, M6.3-M6.8, M7.0-M7.1 and subsequent 1.0 work.
- Corrected the stale RGB/alpha row in the MATLAB validation matrix and added
  the existing M6.1 rich-scatter evidence.
- CITATION.cff stays on the latest actually released version, 0.5.0.

## Native MATLAB evidence

Validated with MATLAB R2026a Update 4 on Windows.

That existing recorded evidence remains unchanged. On 2026-09-13, the resumed
environment additionally ran a figure startup smoke and the existing focused
M6.1 (29/29) and M6.2 (26/26) reader/IR/renderer suites under MATLAB R2026a
Update 5 on Windows, version 26.1.0.3346908. This limited new run is not a full
native workflow/TeX qualification or a general update of the support matrix.

## Portable and repository validation

The public gate passed 140 core cases and eight curated LuaLaTeX compilations
with GNU Octave 11.3.0 in the same digest-pinned Linux image used by hosted CI.
The local image adds the established TeX/PDF/Python dependencies and PowerShell.
Its TeX identifies as TeX Live 2025/Debian; this new evidence is distinct from
the historical TeX Live 2026 validation claim. Native Windows reader evidence
and container-based TeX evidence are not combined into a native Windows
end-to-end claim.

The first container run completed core/TeX cases but its final Git check read
Windows CRLF files with Linux defaults. Applying matching autocrlf configuration
inside the ephemeral test container resolved that environment mismatch; the
complete public gate then passed. No repository Git policy or checks were
weakened. The initial image download also required a retry after a TLS error.

Six architecture checks, existing documentation-link and confidentiality checks,
additional links across every changed/new guide, CITATION 0.5.0 validation,
actionlint 1.7.7, and the working-tree whitespace check pass.

Extended portable regression passed 233/233; focused rich-scatter TeX passed
9/9 and rich-image TeX passed 11/11. The complete local runner finished with
MASTER_PHASE_VALIDATION_PASS. These suites overlap the public core cases and
must not be summed as disjoint native-support evidence. No new visual behavior
was introduced or separately approved in this documentation-only phase.
Hosted acceptance remains pending until all three required PR jobs succeed.

## Compatibility and next work

No product source, tests, public options, FigureIR schema, manifests, profiles,
or compiler behavior changed. No release/tag is created by this phase.
S1 security hardening is next after this phase is accepted and merged.

## Completion decision

Local acceptance passed; ready for PR and the three required hosted checks.
