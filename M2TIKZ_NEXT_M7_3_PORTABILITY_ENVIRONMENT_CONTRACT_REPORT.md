# M7.3 - Portability and environment contract

## Baseline

Public main `1b2768911cf509986abe80f09e7ad48ba9726b6f` after M7.2 PR #15.
All three required jobs succeeded in run 35138594952 on exact head
`b2de781775238c3a1fa243c47a18663abfa9cac2`; mergeability, merge ancestry,
fast-forward, branch cleanup and clean tree were verified. This phase uses
`m7.3/portability-environment-contract`. No tag/release is authorized.

## Contract and changes

[ENVIRONMENT_CONTRACT.md](docs/ENVIRONMENT_CONTRACT.md) separates native MATLAB
Windows, local container Octave, hosted Linux Octave, historical TeX Live 2026
and observed local TeX Live 2025/Debian. It defines host path syntax, spaces,
Unicode, relative assets/manifests, temporary staging, UTF-8/LF, numeric locale,
compiler discovery/quoting, stdout/stderr, error outcomes and trusted TeX.

The workflow remains synchronous without a built-in timeout. External job
supervision is necessary; no unrequested timeout option or stronger process
sandbox promise is introduced. Standalone figure compilation does not validate
arbitrary journal preambles/fonts. Installation guidance now makes these limits
and the MATLAB JVM requirement explicit for an external tester.

The baseline encoding probe already passed in current MATLAB: this is not a
claim that observed baseline files were corrupt. The text writer now encodes
UTF-8 explicitly, checks lossless roundtrip before opening the file, retains
empty writes and checks byte count/close status independently of default
runtime encoding. Generated ASCII products remain unchanged.

The baseline PNG failure probe returned a vendor-specific MATLAB error.
Encoding/open/normalization errors now use the existing
`M2T2:E_PNG_WRITE_FAILED`; normalized PNG writes also check count/close status.
Public API options, FigureIR, scientific data, PNG channel precision and
manifest schema remain unchanged. No new graphics family or fallback appears.

## Focused evidence

Validated with MATLAB R2026a Update 4 on Windows.

Historical evidence is unchanged. New native execution uses explicitly
authorized MATLAB R2026a Update 5 on Windows. Real native workflow compilation
uses the Linux LuaLaTeX bridge, not an asserted native Windows TeX installation.
Local Octave is 11.3/gnuplot in Linux. No other runtime release is claimed.

Both runtimes pass twelve focused cases: UTF-8 bytes, canonical JSON/TeX/RGBA,
write and asset errors, missing compiler, missing/empty/invalid PDF, unsafe
arguments, path normalization, decimal syntax, three real spaced/Unicode/nested
path exports, a two-figure set and a deliberate real TeX error. The common
document plus path/set exports produce six valid PDFs in each runtime.
Compiler failure checks also verify restoration of TeX environment variables.

The new tests exposed an Octave nested-cleanup closure limitation; the fixture
helper was moved to an ordinary subfunction. Octave also rejected empty input
to native2unicode, so the explicit writer now handles empty text separately.
These intermediate failures were corrected and rerun, not labeled successes.

Windows MATLAB and local Linux Octave produce identical reviewed JSON and TeX
bytes. The committed test SHA-256 values are respectively
`52230ae7660109e24dff747b080b104d21e3e133a9d83d7ee06ac739e403b066` and
`a421f46af46be2743f970c09c0fd352aac3f4697470dba02d462f11a7d9c2ac1`.
Hosted CI must reproduce those same goldens. Native encoder PNG bytes differ,
but exact decoded RGB and alpha arrays agree. PDF byte equality is not required.
An actual generated German locale reports a comma decimal separator and passes
the nine focused noncompiler cases plus all eight M6.8 determinism checks.

## Acceptance status

Final full portable regression passes with process exit zero and
`MASTER_THROUGH_M73_VALIDATION_PASS`: 140 core and 235 extended checks, eight
curated PDFs, accumulated security/graphics/large-data/determinism gates, M7.0
API and M7.1 IR/PDF suites, the 15 M7.2 compiler cases, and all twelve M7.3
cases. The final native run also exits zero: twelve focused cases, Windows
security checks, eight determinism cases, eight API cases and 18 IR cases.
The six valid native M7.3 PDFs were rendered and visually inspected, including
the literal symbols/umlauts, Greek math, hybrid alpha and nested/Unicode paths.

Six architecture invariants, documentation links, citation 0.5.0, actionlint
and whitespace checks pass. Staged public files receive the confidentiality
check before commit. Generated artifacts and intermediate failure evidence
remain ignored locally. No remotes, tags, releases or security settings change.

Hosted repository-policy, octave-tests and tex-preview on the exact head remain
mandatory before merge. This is local PR readiness, not a premature hosted
success, feature-freeze, release or external MATLAB support claim.

READY FOR M7.3 PORTABILITY AND ENVIRONMENT CONTRACT PR
