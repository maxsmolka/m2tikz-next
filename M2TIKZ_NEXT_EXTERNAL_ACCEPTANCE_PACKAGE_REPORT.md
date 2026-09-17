# External acceptance package report

## Baseline and scope

Baseline: `9f963c73368483e8fd0c9d48fc617f477781b812`, merged publication-title
fix PR #18. The original uncommitted package was saved locally, then recreated
on this fixed main after successful CI, merge and fix-branch cleanup. Both the
new publication-geometry gates and package gates are retained.

The optional explicit-handle helper delegates to `m2t.export`, refuses existing
sessions and writes ignored local summaries. Results contain neutral IDs,
runtime/revision/tool metadata, export/compile states, diagnostic codes and
timings, not source arrays, figure labels, paths or raw messages. Scientific
acceptance starts at NEEDS_REVIEW. A manual checklist and redacted feedback
template cover the six requested outcomes. No registry or upload exists.

## Checks completed

Fresh complete portable acceptance on the fixed baseline passed: Public
Preview/examples, extended suites, publication/sets, rich scatter/images,
S1, M6.3-M6.8, API/IR/runtime/environment and the 13-case package suite.
Native MATLAB R2026a Update 5 on Windows passed all 13 package cases plus
P01-P13/default controls, runtime/environment, security, API and FigureIR
regressions. Real Linux LuaLaTeX compilation through the documented native
bridge is used; no native Windows TeX or new MATLAB version is inferred.
Both fresh 26-PDF geometry matrices passed, and the helper's 85 mm PDF passed
complete glyph/title/page checks and explicit visual review in both runtimes.
All architecture, documentation, citation, confidentiality, YAML/actionlint and
whitespace checks passed. Git ignores local session products by default.
These are new post-fix runs, not reused pre-fix acceptance claims.

## Resolved interruption

The previous phase stopped on a real 85 mm short-title crop. The dedicated
fix now reserves physical untiled gutters while preserving canonical widths,
typography and scientific values. P01-P13/default controls, actual glyph/page
bounds, native/portable regression and explicit visual review passed before
PR #18 merged. See M2TIKZ_NEXT_PUBLICATION_TITLE_CLIPPING_FIX_REPORT.md.
The helper fixture now uses the same ordinary `Acceptance` title and keeps
its long privacy sentinel in unrendered source DisplayName metadata; both
must be absent from the JSON summary. This is not a product text-shrinking
workaround: the independent short-title geometry regression remains mandatory.

## Decision and next action

No real external figures, data or new MATLAB-version evidence are included.
No public m2t API, tag or release is added. External scientific acceptance
remains manual and requires actual runs on the tester's different MATLAB
version. Select 5-10 critical figures, keep products local and share only
redacted findings. Then triage feedback before M8.0/RC/burn-in/1.0 work.

Local acceptance is complete. Required exact-head repository-policy,
octave-tests and tex-preview must succeed before merge. The master execution
report records the eventual PR/merge/cleanup evidence separately.
