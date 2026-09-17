# Local external acceptance package

Start with [the testing guide](../../docs/validation/EXTERNAL_ACCEPTANCE_TESTING.md).
`runExternalAcceptance.m` is an optional validation utility, not a third public
export API. It delegates to `m2t.export`; it does not discover, restyle, close,
serialize or upload source figures. Supply explicit live handles and neutral IDs.

The utility creates a **new** `.audit/external-acceptance/session-...` directory
under this checkout. Git ignores `.audit/` by default. Existing sessions are
refused; use a new ID for reruns and serialize concurrent runs. Do not force-add
this directory. TeX, PNG, PDF and compiler logs can contain sensitive source
content even though the summary JSON excludes source data and raw diagnostics.
Keep the entire session local and apply your own access/retention controls.

`results.json` schema 1 records the runtime version/update, OS family and
architecture, supplied revision and TeX version, selected export options and
ordered per-case results. Each case records export/compile booleans, workflow
status, diagnostic **codes only**, stage timings in seconds, outcome,
`visualSemanticResult` and `note`. Timings are approximate, not performance
guarantees; `analysis` includes reading/normalization and is separate from
`export` serialization/assets and `compile`. An interrupted session can have
only a prefix of cases; compare IDs with your intended list.

The six outcomes are `PASS`, `PASS_WITH_VISUAL_DIFFERENCE`,
`UNSUPPORTED_EXPECTED`, `FAIL_PRODUCT`, `FAIL_ENVIRONMENT`, `NEEDS_REVIEW`.
The helper starts every case at `NEEDS_REVIEW` / `NOT_REVIEWED`, including
successful PDFs and unsupported input. Only a precise missing-compiler code
automatically sets `FAIL_ENVIRONMENT`. A compiler error alone does not establish
whether the product, trusted input text, installation or surrounding environment
caused the problem. The tester must review and classify it.

Edit the local JSON outcome/result/note after comparing the original and PDF;
leave recorded status/booleans/timings intact. The summary stores no scientific
arrays, names, labels, source paths, hostnames, license details or screenshots.
Do not paste sensitive content into metadata, notes or the manually supplied
TeX-version line. A sanitized summary is still not automatically public-safe.

Use [the feedback template](FEEDBACK_TEMPLATE.md) only after manual redaction.
There is no registry, discovery service, network call or automatic upload.
