# Test strategy for m2tikz-next

## Purpose

No single test type can establish that generated scientific graphics are both
stable and correct. The 2.0 test strategy therefore uses four complementary
levels. M1B introduces only focused regressions and review tooling; it does not
introduce a new framework.

## 1. Unit and focused regression tests

Small tests isolate a known technical cause and assert observable behavior or a
pure helper result. They must not depend on full-file hashes. Examples include
strict logarithmic labels, Octave bar/colorbar object capabilities, and the M1B
camera-projection scenarios. These tests should be fast, deterministic, and run
on every supported MATLAB and Octave job.

## 2. Semantic export validation

Semantic checks inspect generated structure: nonempty output, expected axis and
plot constructs, labels/legends, referenced data/assets, finite-value policy,
diagnostics, and determinism. Generic checks can reject corrupt output but cannot
prove that a complex plot retained its scientific meaning. Each plot family
should gradually acquire a case-specific oracle describing expected object and
series counts, coordinate bounds, labels, and representation choices.

## 3. Golden-output regression

Golden hashes detect every byte-level output change. They are valuable after an
output has been semantically and visually approved, but a matching hash proves
only identity with that approval—not correctness by itself. Golden tables are
environment-specific where rendering/object models legitimately differ. New or
changed hashes require traceable case, artifact, compiler status, review status,
and approval rationale. Missing approval must remain a failure or explicit
unreviewed state; bulk hash regeneration is prohibited.

## 4. TeX compilation and visual validation

Standalone outputs are compiled with the supported engine matrix and checked for
assets and PDFs. Compilation catches invalid TeX and package compatibility, but
does not catch wrong data or layout. Selected/high-risk cases additionally
compare a native rendering with the compiled TikZ rendering using the process in
`VISUAL_VALIDATION.md`, followed by manual approval when automated tolerance is
insufficient.

## Gating

- Pull requests: levels 1 and 2, approved Golden diffs at level 3, and a compact
  level-4 compile matrix.
- Scheduled/platform jobs: complete ACID Golden and compilation matrices.
- Release candidates: MATLAB/Octave platform matrix plus visual review of new or
  materially changed Goldens.

Failures must retain their stage classification: fixture/dependency, exporter,
semantic, Golden mismatch, asset, TeX engine, or visual difference.
