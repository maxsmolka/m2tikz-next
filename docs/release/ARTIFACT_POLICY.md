# Release artifact policy

## Source-controlled public material

- production source under `src/`;
- test and benchmark source;
- user and contributor documentation, ADRs, validation plans, and release
  policies;
- small deterministic fixtures needed to reproduce a test;
- curated human-readable result summaries when they materially support a public
  claim and contain no local paths or personal data.

## Generated or local material

- compiler logs and TeX auxiliaries (`*.log`, `*.aux`, `*.fdb_latexmk`, `*.fls`);
- generated PDFs, TeX, PNG assets, rasters, and difference images;
- benchmark output and machine timing tables;
- local TeX/font caches and temporary test products;
- `.audit/`, `build/`, and equivalent local working directories unless a
  particular small artifact is explicitly curated.

Rules must be path-specific. TeX, PDF, PNG, and TSV formats are not globally
ignored because examples and reviewed fixtures may legitimately use them.

## Future GitHub release contents

A GitHub release should be source-first: the reviewed repository source,
license and attribution files, user documentation, tests, examples, and small
required fixtures. A source archive generated from the approved tag is the
preferred release artifact unless a separately reviewed package format is
introduced.

Do not bundle generated local build directories, private or external validation
inputs, private data, MATLAB license/runtime material, TeX caches, compiler
intermediates, or unnecessary generated test output. A generated artifact
becomes public only through an intentional review decision, never merely
because a validation script produced it.
