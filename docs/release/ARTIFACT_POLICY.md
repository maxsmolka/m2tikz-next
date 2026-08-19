# Audit and generated-artifact policy

## Source-controlled public material

- production source under `src/`;
- test and benchmark source;
- ADRs, design documents, validation plans, support/release policies, and
  milestone reports;
- small deterministic fixtures needed to reproduce a test;
- curated human-readable result summaries when they materially support a public
  claim and contain no local paths or personal data.

## Generated or local material

- compiler logs and TeX auxiliaries (`*.log`, `*.aux`, `*.fdb_latexmk`, `*.fls`);
- generated PDFs, TeX, PNG assets, rasters, and difference images;
- benchmark output and machine timing tables;
- local TeX/font caches and temporary test products;
- `.audit/m2.1/`, `.audit/m2.2/`, `.audit/m2.3/`, and future equivalent working
  directories unless a particular small artifact is explicitly curated.

Rules must be path-specific. TeX, PDF, PNG, and TSV formats are not globally
ignored because examples and reviewed fixtures may legitimately use them.

## Historical evidence already tracked

The inherited/modernization history tracks extensive `.audit` evidence,
including hundreds of PDFs, logs, auxiliary files, TeX files, and tables. Its
original role was milestone auditability and Golden review. M2.4B moved the
required version-1 JSON migration fixture to `test/fixtures/ir/line-v1.json` and
relocated two source audit harnesses to `benchmarks/runLegacyRuntimeAudit.m` and
`benchmarks/runLegacyPerformanceAudit.m`. No generated `.audit` path is consumed
as test input. Durable summaries remain under `docs/development/`; all 2,497
tracked `.audit` paths were removed from the current tip through deletions or
these reviewed moves. Git history was not rewritten.

The complete `.audit/` working directory is now ignored. New validation runs
write there, and reports cite stable summaries rather than checked-in compiler
caches. A generated artifact becomes public only through an intentional review
decision, never merely because a validation script produced it.
