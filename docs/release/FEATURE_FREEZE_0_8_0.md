# 0.8.0 feature-freeze release

Version **0.8.0**, tagged `v0.8.0`, is the feature-freeze / pre-1.0 acceptance
release. It is an immutable reference for external testing, not production-
complete 1.0 or universal graphics support. The finalized
[release notes](RELEASE_NOTES_0_8_0.md) define its scope and evidence.

## Freeze policy

> After the v0.8.0 feature-freeze candidate, no new major graphics family is
> planned before 1.0 unless external acceptance testing reveals a critical
> correctness/usability gap that cannot reasonably be deferred.

Allowed work after this candidate:

- bug and scientific-correctness fixes;
- better diagnostics and explicit unsupported outcomes;
- compatibility and portability fixes backed by real runtime evidence;
- fixes for performance regressions without data reduction;
- documentation, security and release engineering;
- narrowly necessary gaps established by real acceptance testing.

Missing MATLAB plot families, speculative features and unrelated API expansion
are not automatically authorized. A proposed exception must identify the real
blocking workflow, why deferral is unreasonable, the smallest faithful scope,
synthetic regression coverage and remaining unsupported behavior. Do not publish
the tester's actual figures or data. API breaks additionally require the
exceptional justification, ADR and migration process in [API.md](../API.md).

## Frozen candidate boundaries

The end-user APIs are `m2t.export` and `m2t.exportSet`; there are no new aliases
or options. FigureIR v2, manifest schema 1 and internal implementation namespaces
are independent of repository version 0.8.0. Stored data follows
[FigureIR compatibility](../FIGURE_IR.md); internal helpers are not promoted to
public APIs. [Support](../SUPPORT.md), [runtime compatibility](../RUNTIME_COMPATIBILITY.md)
and [environment requirements](../ENVIRONMENT_CONTRACT.md) remain authoritative.

This candidate does not promise arbitrary 3-D scenes, perspective/lighting,
general patches, polar/contour families, modern boxchart, broad bar variants,
scatter transparency, dynamic/nested layouts, unbounded dual-Y semantics,
automatic downsampling or whole-figure raster/legacy fallback. Nonwhite axes
backgrounds and several unrepresented presentation properties fail explicitly.
Bounded 3-D viewport/tick proximity needs particular external visual review.

MATLAB evidence remains the exact recorded releases/updates and platform:
historical R2026a Update 4 and newer R2026a Update 5 on Windows. Octave evidence
is 11.3 on observed Linux environments. Another MATLAB version becomes evidence
only after an external test actually runs. Native MATLAB's local compiler
bridge does not establish native Windows TeX validation. Calls have no built-in
compiler timeout. These are known boundaries, not reasons to label untested
environments supported.

## Release process

Publication requires:

1. Select the reviewed merged commit and rerun required gates as appropriate.
2. Review the [source-first artifact policy](ARTIFACT_POLICY.md), attribution,
   security, installation, known limits and finalized notes.
3. Explicitly approve final version/citation/release metadata and release date;
   never backdate preparation or relabel historical evidence.
4. Obtain separate authorization for the tag and GitHub Release.

External acceptance is the next engineering activity: use the
[generic local package](../validation/EXTERNAL_ACCEPTANCE_TESTING.md), then test
roughly 5-10 critical real figures in another MATLAB
version, triage feedback, and proceed to M8.0 RC readiness, v0.9.0 /
v1.0.0-rc.1, M8.1 burn-in and v1.0.0. The package is included in v0.8.0;
this document does not assert that external testing has happened.
