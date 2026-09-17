# External real-world MATLAB acceptance

The feature-freeze candidate is ready for evaluation, not a promise that your
MATLAB version or scientific figures are supported. Latest published release
is still 0.5.0. Test the reviewed development commit, or a subsequently separately
authorized tag, and record exactly which one you used.

The publication-title clipping fix is included in this package's baseline.
Titles still belong in the manual checklist: passing compilation is not a
generic visual-quality guarantee. See the [profile geometry contract](../PUBLICATION_PROFILE.md).

Validated with MATLAB R2026a Update 4 on Windows.

That is historical evidence. New local evidence uses R2026a Update 5 on Windows;
see [runtime compatibility](../RUNTIME_COMPATIBILITY.md) and the
[environment contract](../ENVIRONMENT_CONTRACT.md). Another MATLAB release is
**new evidence only after an actual run**, never merely because this package
was provided. Native Windows TeX remains a separate unverified environment.

## Select and prepare locally

1. Choose roughly **5-10 genuinely important figures**, prioritizing difficult
   real workflows over artificial breadth. Keep their actual names, data and
   research context in your own local notes. Use neutral `case-001` IDs here.
2. Follow [installation](../INSTALLATION.md). Use the JVM-enabled MATLAB session,
   add `src` to the path, and check LuaLaTeX, TikZ, PGFPlots and `standalone`.
   Run `lualatex --version` in your terminal; record its short version line and
   distribution. No compiler is downloaded or installed by this package.
3. Record the actual commit using `git rev-parse HEAD` (or the exact approved
   tag), MATLAB `version` including update, and OS/version locally. The helper
   records `version`, OS family and architecture; add the OS version to local
   session notes if relevant. Do not collect usernames, hostnames or licenses.
4. Read the [support boundaries](../SUPPORT.md). Preserve the original figure
   as the comparison reference; do not silently remove unsupported content to
   obtain a successful export. Any deliberate source adjustment is a separate
   test with an explicit local note.

Only process trusted source figures/text and trusted TeX. This workflow invokes
a local compiler and is not a sandbox. It has no built-in compiler timeout.
An externally terminated session may leave partial products/results; inspect
them locally and start a new session ID rather than overwriting evidence.

## Optional local helper

From the checkout root, with your explicit live figure handles:

```matlab
addpath('src');
addpath(fullfile('validation','external-acceptance'));
cases(1) = struct('id','case-001','figure',figureOne);
cases(2) = struct('id','case-002','figure',figureTwo);
% Replace both placeholders with actual observations; the revision is validated.
testedRevision = 'ACTUAL_COMMIT_HASH';
texVersion = 'ACTUAL_LUALATEX_VERSION_LINE';
[report, reportPath] = runExternalAcceptance(cases, 'session-01', ...
    testedRevision, texVersion);
```

This uses the unchanged public defaults: source profile, vector image backend,
no overwrite. For a deliberately selected image/publication workflow:

```matlab
[report, reportPath] = runExternalAcceptance(cases, 'session-02', ...
    testedRevision, texVersion, 'ImageBackend','auto', ...
    'Profile','publication','Width','single-column');
```

Auto/hybrid applies only to supported image layers, never whole figures. These
choices are recorded. To compare different options, use separate neutral
session IDs. The helper uses `m2t.export`, the same workflow an end user calls;
it is validation infrastructure, not a new frozen public export API. It does
not discover other open figures, restyle/close caller figures or upload anything.

If LuaLaTeX is unavailable, pass `not available` as its version. The helper
still attempts the normal public workflow and records the missing-compiler
diagnostic; there is no hidden TeX-only mode. Use manual `m2t.export` calls and
the feedback template if you prefer not to use the helper.

## Scientific and visual review

Open each original and exported PDF side by side. Check:

- all data are present, including gaps, endpoints and overlapping series;
- axes limits, scales and direction, labels and custom ticks;
- legend membership/order/labels, colors, colormaps and colorbars;
- per-point marker sizes/colors, image placement and alpha;
- layout ownership, spans and shared labels;
- both Y axes, their units/limits/ticks and series ownership;
- 3-D view, depth ordering and scientific interpretation;
- annotations, clipping and publication dimensions/legibility.

Compilation success alone is **not PASS**. A missing point, altered unit,
incorrect axis ownership, lost alpha or changed scientific meaning is not a
cosmetic difference. Pixel-perfect antialiasing and byte-identical PDFs are
not required; inspect semantics and publication usability.

| Outcome | Tester decision |
| --- | --- |
| PASS | Export and compilation succeed; all relevant scientific/visual checks pass. |
| PASS_WITH_VISUAL_DIFFERENCE | Meaning is preserved; describe the nonblocking visual difference. |
| UNSUPPORTED_EXPECTED | Explicit rejection matches documented limits; no partial result is accepted. |
| FAIL_PRODUCT | A supported workflow is wrong or unexpectedly fails; preserve local evidence. |
| FAIL_ENVIRONMENT | A demonstrated installation/tool/process environment problem prevents acceptance. |
| NEEDS_REVIEW | Evidence is incomplete or the cause/semantic impact is uncertain. |

The initial `NEEDS_REVIEW` / `NOT_REVIEWED` values must be manually reviewed.
Only a precise missing-compiler code is automatically `FAIL_ENVIRONMENT`.
An unsupported result is not automatically expected, and a compilation failure
is not automatically a product defect. Keep diagnostic codes, approximate
analysis/export/compile timings and a short local note for every case.

## Local evidence and safe feedback

The [package README](../../validation/external-acceptance/README.md) defines
the JSON summary. It records no source data; all output is under ignored
`.audit/external-acceptance/`. TeX/PNG/PDF/log files **do contain figure content**.
Do not upload the directory or force-add it to Git. Ignore rules are not access
control. Manually edited notes or version fields can also disclose information.

Review and edit the local JSON `outcome`, `visualSemanticResult` and `note`;
retain the original measurements. Compare recorded case IDs against the intended
list to detect interruptions. Preserve local evidence under your own policy.
Manually copy only redacted findings into the
[public-safe feedback template](../../validation/external-acceptance/FEEDBACK_TEMPLATE.md).
Never attach original figures/data/screenshots/full logs without separate
deliberate disclosure approval. Prefer a minimal synthetic reproduction.

## Triage and next milestone

Triage correctness first, then compatibility, portability, reproducibility,
diagnostics and usability. Distinguish environment repair, documented limits,
cosmetic feedback and true product defects. A critical new graphics gap needs
the [freeze exception review](../release/FEATURE_FREEZE_0_8_0.md); this package
does not authorize speculative expansion or declare external acceptance done.
Next: feedback triage, M8.0 RC readiness, v0.9.0 / v1.0.0-rc.1, M8.1 burn-in,
then v1.0.0. Tags/releases require separate authorization.
