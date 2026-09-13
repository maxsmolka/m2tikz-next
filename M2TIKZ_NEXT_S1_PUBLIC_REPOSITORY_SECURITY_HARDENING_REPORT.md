# S1 public repository security hardening

## Baseline and scope

Baseline: public/main at 934b05f60c25690df212c2f664d6ad1d6f4c5e16 after
the post-M6.2 alignment. Latest release remains 0.5.0. This phase hardens
repository controls and export boundaries; it introduces no graphics family,
public option, FigureIR schema change, reduction or legacy fallback.

## Hosted security inspection (2026-09-13)

Read-only inspection first confirmed that private vulnerability reporting,
secret scanning and push protection were enabled. The main branch had no
protection or ruleset; Dependabot alerts and automated security fixes were
disabled. Authenticated repository administration was available through the
existing Git credential integration. No credentials were stored in Git or
printed in evidence.

Enabled and verified missing safe controls: main requires an up-to-date PR
with repository-policy, octave-tests and tex-preview; force pushes/deletion
are blocked and administrator enforcement is enabled. Stale reviews are
dismissed; zero additional approving reviewers preserves the single-maintainer
workflow while requiring PR integration. Dependabot alerts and automated
security fixes are now enabled. Existing scanning/reporting controls were
preserved. No permissions/protections were weakened, and no history, tags,
releases, remotes or unrelated branches were changed.

## CI supply chain

The workflow retains contents:read and ordinary pull_request execution; it
does not introduce pull_request_target. All three actions/checkout references
are pinned to 11d5960a326750d5838078e36cf38b85af677262, the observed v4 ref
on the inspection date. Readable provenance is retained beside each pin.
Octave 11.3.0 already uses an immutable image digest. actionlint remains on
explicit version 1.7.7. Distribution packages remain distribution-managed,
not fully locked; the security policy documents this residual update surface.

## Export boundary changes

- Preflight examines TeX/PDF/log products, assets and set manifests before
  changing existing products. Final symbolic links (including dangling links),
  directory/file conflicts and unknown/nested assets fail explicitly.
- Asset cleanup no longer recursively deletes a caller-controlled directory.
  Only flat generated image names are eligible; foreign contents are preserved.
- Caller-chosen absolute/relative/parent-relative paths remain supported. No
  repository-only sandbox is imposed. Dotted stems now retain their complete
  spelling in asset references; spaces/underscores compile successfully.
- Control and unsafe TeX/path characters are rejected. Windows also rejects
  device names, alternate data stream colons and shell-expansion characters.
  Hybrid asset references cannot escape through path components or TeX tokens.
- Compiler arguments are quoted and validated, PDF/failure-log destinations
  checked, and shell escape explicitly disabled. Temporary compiler staging
  and environment restoration remain in place.
- Literal text is escaped; tex/latex markup retains deliberate mathematical
  semantics. SECURITY.md explicitly requires trusted figures/TeX: disabling
  shell escape does not sandbox Lua or TeX filesystem access.

MATLAB uses JVM path inspection (and fails explicitly without a JVM); Octave
uses lstat. The output directory must be trusted and not modified concurrently
by an adversary. Hard links and filesystem races are outside this isolation
contract. A set does not promise whole-set transactional replacement.

## Focused evidence

MATLAB R2026a Update 5 on Windows: 14/14 S1 tests, including Windows names;
existing M6.1 rich-scatter 29/29 and M6.2 rich-image 26/26 regressions passed.
Three additional native Windows cases pass: existing/dangling junction products
are rejected and an explicitly linked parent directory remains allowed. An
initial canonical-path-only implementation failed the junction test; final
inspection uses no-follow file attributes and real-path resolution. The failed
probe prevented acceptance until this Windows-specific gap was corrected.
This new evidence does not replace the existing statement:

Validated with MATLAB R2026a Update 4 on Windows.

GNU Octave 11.3.0 Linux: 18/18 S1 tests, including file/dangling/asset-directory/
asset-file/manifest symlink cases. Initial fixture failures were corrected:
Octave nested callback captures needed local bindings, and the manifest fixture
needed the actual m2t-manifest.json name. Product preflight passed the corrected
cases without changing outside sentinel files.

Three separate LuaLaTeX tests passed: dotted/space/underscore hybrid path,
owned-product overwrite, and an engine assertion that shell escape is disabled.
Container TeX evidence is TeX Live 2025/Debian, separate from native Windows
reader/path evidence. No new native Windows end-to-end TeX claim is made.

## Complete regression and acceptance

The complete portable runner passed 140 public core cases, eight curated PDF
compilations, 233 extended cases, nine focused rich-scatter TeX cases and eleven
focused rich-image TeX cases. These suites overlap; their counts are not
disjoint native-support claims. Six architecture invariants, documentation
links (including all changed guides), CITATION 0.5.0, confidentiality, actionlint
1.7.7 and whitespace checks pass. No visual-layout feature was introduced;
path/compiler checks verify real PDFs without claiming new visual approval.

The runner completed with MASTER_PHASE_VALIDATION_PASS. The subsequent
Windows-only path-inspection correction is covered by rerun native evidence;
the Octave path is unchanged.
Focused suites are added to hosted CI. All three required hosted jobs must
succeed on the PR head before merge. The next phase is M6.3; its new MATLAB
tiledlayout claims require native MATLAB acceptance.
