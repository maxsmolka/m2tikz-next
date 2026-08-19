# m2tikz-next – M1A Report

## Executive Summary

M1A establishes a reproducible Windows 11 / GNU Octave 11.3 test baseline on
the requested starting commit `806c97d99f87f8a1e99a7c54e853c25c82aac301`.
The legacy ACID suite now starts from Git Bash with a native Windows Octave path,
copies its template portably, hashes generated files on current Octave, and
executes all 105 cases. No Golden/MD5 reference was changed.

The three M0 runtime defects have focused, golden-independent regressions. All
three failed on the unchanged product and pass after minimal fixes. The final
ACID result remains 0/90/15 (pass/fail/skip), because no Octave 11.3 Golden table
exists; the final run nevertheless exports 82 files that reach hash comparison.
The remaining non-Golden failures are understood Octave compatibility or fixture
prerequisite issues. A selected TeX matrix and a non-unit large-data benchmark
were added, along with policy/design records for engines, large data, and future
diagnostics.

## Test Infrastructure Changes

The initial environment was verified as GNU Octave 11.3.0 and latexmk 4.88 on
Windows. Productive changes are separate from the pre-existing untracked M0
material under `.audit/`, `MATLAB2TIKZ_CURRENT_STATE_AUDIT.md`, and
`MATLAB2TIKZ_M0_RUNTIME_BASELINE.md`.

- `runtests.sh` prefers `octave-cli`, quotes executable paths, and translates a
  Git Bash test directory for native `.exe` runners without hardcoded drives.
- `test/private/testMatlab2tikz.m` copies each template entry instead of relying
  on fragile `template/*` wildcard expansion in Octave on Windows.
- `test/private/calculateMD5Hash.m` uses Octave's binary-safe built-in `hash`
  when the removed `md5sum` helper is unavailable. Its result was cross-checked
  against `Get-FileHash` for the same generated file.
- `test/README.md` documents the legacy, regression, and TeX compile entry points.

The original pre-test infrastructure failure is eliminated: all 105 test cases
are entered, and infrastructure errors in the final run are zero.

## ACID Baseline

Final run: `.audit/runtime-baseline/logs/m1a-acid-final.log`.

| Metric | Count |
|---|---:|
| Executed | 105 |
| Passed | 0 |
| Failed | 90 |
| Skipped | 15 |
| Infrastructure errors | 0 |
| Hash/reference mismatches observed | 82 |

The pass count is zero because `ACID.Octave.11.3.0.md5` does not exist, so every
successful export is compared with an empty expected hash. The 90 failed test
cases have this mutually exclusive primary classification:

| Primary classification | Tests | Evidence |
|---|---:|---|
| OUTDATED/MISSING GOLDEN FILE only | 78 | Successful export followed only by empty-reference mismatch |
| OCTAVE COMPATIBILITY | 12 | Eight `x_viewtransform` export failures; four plot-fixture failures |
| PRODUCT FAILURE | 0 | The three confirmed M0 failures are fixed |
| TEST INFRASTRUCTURE | 0 | Suite and hash/copy stages operate |
| TEX FAILURE | 0 | ACID headless mode does not compile TeX |
| UNKNOWN | 0 | Every failure has a reproduced cause |

There are 82 hash mismatches rather than 78 because four Octave fixture failures
still leave an exportable figure and subsequently also reach hash comparison.
The 12 compatibility cases are:

- ACID 2, 9, 29, 30, 31, 56, 73, 81: legacy access to Octave's absent internal
  axes property `x_viewtransform` during export.
- ACID 17: Octave rejects the nonlinear colorbar requested by the fixture.
- ACID 47, 48: `ellip` unavailable; ACID 49: `kaiser` unavailable (Octave signal
  package prerequisite is not present).

Skipped cases are ACID 12, 42–44, 46, 54, 59, 62, 71–72, 75–76, 80, 82, and 98.
Golden files were deliberately left untouched.

## Regression Tests Added

`test/runM1ARegressionTests.m` contains three observable-output tests independent
of MD5 tables:

1. `M2T-RUNTIME-001`: strict logarithmic ticks must emit `10^{...}` labels.
2. `M2T-RUNTIME-002`: an Octave grouped bar plot must export `ybar` output.
3. `M2T-RUNTIME-003`: image plus colorbar must export both default and manual
   colorbar placement.

Before product fixes: executed 3, passed 0, failed 3, skipped 0. Final: executed
3, passed 3, failed 0, skipped 0.

## Bugs Fixed

- M2T-RUNTIME-001 now formats the current tick label rather than the undefined
  variable `str`.
- M2T-RUNTIME-002 selects the first bar child that actually has `FaceColor`,
  instead of querying the accompanying line child in Octave's hggroup.
- M2T-RUNTIME-003 obtains associated axes through the public `Axes` capability
  when present and Octave's `__axes_handle__` capability otherwise. The same
  lookup is used for manually positioned colorbars discovered by the full suite.

No broad exception handler, version check, public API change, or architectural
refactor was introduced.

## Octave Compatibility Findings

Octave 11.3 represents each bar series as an hggroup with both line and patch
children; only the patch has `FaceColor`. Its colorbar is axes-like and exposes
the associated plot axes as `__axes_handle__`, not MATLAB's `ColorBar.Axes`.
Octave also lacks the `x_viewtransform` internal axes property assumed by eight
legacy 3D paths. Those 3D failures were not folded into the three scoped fixes.

The post-change M0 audit harness reports 18 cases: 17 exported and deterministic,
and one (`histogram`) not testable because Octave has no implementation. Bar and
colorbar, which failed in M0, now export deterministically.

## TeX / Unicode Decision

ADR-0001 chooses engine-neutral output with documented limits as the compatibility
policy and recommends LuaLaTeX for new Unicode-heavy documents. It does not alter
the API or silently convert Unicode. Existing pdfLaTeX-oriented workflows remain
supported for compatible text/TeX markup.

The automated compile subset exported line, scatter, log-axis, image, surface,
and Unicode fixtures: 6/6 exports passed. Across 12 engine combinations, 11
compiled successfully; raw Unicode with pdfLaTeX was the single
`EXPECTED ENGINE LIMITATION`; there were zero export failures and zero unexpected
TeX compilation failures. Logs and TSV summaries remain under
`test/output/m1a-tex/`.

## Performance Baseline

`benchmarks/benchmarkLargeData.m` preserves the 100 / 10,000 / 100,000 /
1,000,000-point inline and external-data matrix and records export time, TeX
bytes, external file count/bytes, optional LuaLaTeX time/status, and the fact that
portable peak RSS is not measured. It is not called by normal tests. A 100-point
export-only sanity run passed in both modes.

The conserved M0 baseline is: 100 points 0.174 s inline; 10,000 points 0.585 s;
100,000 points 4.767 s; 1,000,000 points 45.156 s and 37,382,643-byte inline TeX.
pdfTeX exceeds its main-memory limit from 100,000 points; the million-point
LuaLaTeX inline run took about 131 seconds. No downsampling or representation
optimization was implemented. Candidate strategies are assessed in
`docs/design/LARGE_DATA_EXPORT.md`.

## MATLAB Validation Required

**MATLAB VALIDATION REQUIRED** for both Handle Graphics compatibility changes:

- child selection in `getPatchDrawOptions` must be checked on pre-HG2 and HG2
  bar/area/patch objects;
- public `ColorBar.Axes`, manual location/unit restoration, and colorbar-to-axes
  association must be checked on supported MATLAB releases.

The strict log-label fix and test-only copy/hash changes are low risk, but the
complete MATLAB ACID and TeX matrix should still run before release. MATLAB was
not available locally, so no claim of MATLAB runtime validation is made.

## Remaining Risks

- There is no reviewed Octave 11.3 Golden table; 82 generated files therefore
  cannot be asserted against approved output yet.
- Eight 3D/object cases depend on `x_viewtransform` and need a separately scoped,
  capability-based compatibility design.
- Four fixtures depend on unsupported behavior or an optional Octave package.
- MD5 tests remain intentionally brittle and establish regression identity, not
  visual correctness.
- LuaTeX needs a writable font cache in restricted environments; the compile
  harness provides an output-local cache.
- Large datasets remain expensive and can exceed TeX engine resources.

`docs/design/DIAGNOSTICS.md` describes stable future codes (`M2T-W001`,
`M2T-W002`, `M2T-E001`) without changing current warning/error behavior.

## Recommendation for M1B

Make M1B a validation and compatibility milestone, not an IR refactor:

1. review the 82 Octave 11.3 outputs visually/semantically and create a Golden
   table only after explicit approval;
2. reproduce and minimally replace the eight `x_viewtransform` assumptions with
   capability-based geometry, with focused 3D regressions;
3. make optional signal-package fixture prerequisites explicit and distinguish
   unsupported Octave plot creation from product export failures;
4. execute the complete matrix on representative MATLAB HG1/HG2-era targets;
5. prototype the internal diagnostic emitter while preserving public behavior.

## Quality Assurance Record

- ACID: 105 executed / 0 passed / 90 failed / 15 skipped; expected baseline exit
  due to 60 reliable failures.
- M1A regressions: 3 / 3 passed.
- Audit harness: 18 total / 17 exported deterministically / 1 not testable.
- TeX subset: 6 / 6 exported; 11 / 12 compiled; 1 expected engine limitation;
  0 unexpected failures.
- Original smoke: pdfLaTeX PASS, one page, 28,928 bytes.
- Benchmark sanity: inline and external modes PASS at 100 points.
- `git diff --check`: PASS; only Git's informational LF-to-CRLF warnings appeared.
- Golden/MD5 updates: none.
