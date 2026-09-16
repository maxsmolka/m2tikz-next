# M7.2 - Runtime compatibility hardening

## Starting state

Baseline public main: `96b3db9270ed4eee7d5db19ea01f3599e6c3294a`, M7.1 merged
in PR #14. Working tree was clean. The phase branch is
`m7.2/runtime-compatibility-hardening`; no tag/release is authorized.

## Audit and changes

The [runtime contract](docs/RUNTIME_COMPATIBILITY.md) inventories required
source state for axes/lines/errorbars, rich scatter, legends/colorbars,
text/annotations, bars/boxplots, fixed tiled layouts, dual Y, scalar/RGB/alpha
images, bounded 3-D, multi-axes ownership and publication profiles.

There are no release-number gates to replace. NumericRuler guards remain
deliberately conservative because property presence alone does not prove
numeric units. Native compound/peer metadata dependencies remain explicit
and fail closed. This is not a multi-version compatibility matrix.

The shared optional-property helper defaults only absent properties; invalid
handles and actual getter failures no longer become apparently valid default
semantics. Axes, figure associations, semantic-property guards, scatter,
colorbars, legends and errorbar aliases use presence inspection. Required
scatter coordinates retain their precise malformed-data diagnostic. Existing
empty values are not replaced by defaults.

Scalar, nonmissing MATLAB strings normalize to char, including when encountered
inside existing cell text. Missing strings and string arrays remain explicit
normalization failures. The helper's optional diagnostic path is now defined
for existing callers that omit it. No public API, schema, graphics-family,
downsampling, whole-figure raster or legacy fallback change is introduced.

## Runtime and evidence separation

Validated with MATLAB R2026a Update 4 on Windows.

That historical statement is unchanged. The user explicitly approved current
MATLAB R2026a Update 5 on Windows for this task's new evidence. Native Octave is
11.3/gnuplot on container Linux. Native MATLAB compilation uses the existing
bridge to real Linux LuaLaTeX/TeX Live 2025 (Debian), not native Windows TeX.

The synthetic R01-R15 suite separately labels native reader versus portable-only
IR evidence, checks canonical replay and deterministic render plans, and can
compile all representatives plus actual public profile/set workflows. Octave
R05-R07 are portable-only: supported MATLAB boxplot/tiled/yyaxis constructors
are unavailable there. MATLAB R10 additionally instantiates a figure arrow.
Octave rejects single AlphaData at graphics construction, so its R09 uses double;
MATLAB R09 uses single. No exporter coercion hides that distinction.

## Validation status

Initial MATLAB reader/IR matrix: 15/15 passed. Initial Octave execution exposed
the single-alpha constructor limitation above; the source-runtime distinction
is recorded and the common double-alpha case is retained.

Additional final checks exposed two test portability defects: direct indexing
of a namespaced function result is accepted by MATLAB but not this Octave, and
the historical M2.3 manual-colorbar fixture had an Octave-only expectation.
The PDF assertion now uses a temporary result variable. The colorbar fixture
checks the actual source Location: unresolved manual orientation must produce
the exact existing unsupported diagnostic, whereas the Octave resolved case
still requires the exact rectangle. No product guard is relaxed.

The final full portable regression passes with process exit zero and
`MASTER_THROUGH_M72_VALIDATION_PASS`: 140 core checks, 235 extended checks,
eight curated preview PDFs, accumulated security/layout/dual/3-D/large-data/
determinism suites, eight API checks, 18 FigureIR checks plus nine PDFs, and
the new 15-case runtime suite with real PDF/profile/set workflows. Source,
test and workflow hashes were unchanged during this final full run.

Native MATLAB passes all 15 new cases and their PDFs plus public profile/set
exports, 205 accumulated native regression cases, and the final M2/M2.1/M2.2/
M2.3 reader, M7.2 and 50-case negative recheck. Octave separately passes its
reader cores, 52 negative cases and 15 runtime/portable compiles. Initial
failures and their test-only corrections are recorded above, not counted as
successful runs. Every final acceptance process exits zero.

All 15 MATLAB representative PDFs and the publication-profile result were
visually reviewed. The source text/arrow fixture now explicitly uses black on
white rather than inheriting the desktop theme; the final text PDF was
recompiled and reviewed. Bounded 3-D viewport/tick proximity remains the
previously documented limitation, not a new parity claim.

Six architecture invariants, documentation links, citation metadata (0.5.0),
actionlint and whitespace checks pass. Confidentiality is checked again on
the staged public files. No raw local evidence, source figures, private paths,
machine identities, new tags or releases are published. Repository protection
and scanning were inspected read-only and remain unchanged.

Required hosted jobs remain repository-policy, octave-tests and tex-preview,
all on the exact submitted head before merge. This report establishes local
PR readiness, not an advance claim of hosted success or merge completion.

READY FOR M7.2 RUNTIME COMPATIBILITY HARDENING PR
