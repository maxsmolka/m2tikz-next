# Architecture

m2tikz-next separates runtime figure inspection from scientific semantics and
serialization. Public entry points are `m2t.export` and `m2t.exportSet`;
`m2t2.*`, FigureIR, and JSON helpers remain internal/experimental.

## Pipeline and ownership

1. `m2t.export` validates options and output naming, then delegates analysis to
   `m2t2.reader.readFigure`. Runtime graphics handles stay in readers.
2. Readers create and validate handle-free FigureIR v2: axes, scientific series,
   explicit layout/placement, ownership, text, legends, colorbars, and annotations.
   Fixed native tiled layouts use explicit grid/cell metadata and resolved
   rectangles; no tiled ownership is inferred from positions.
3. The backend planner selects image representation from validated IR. The
   default is vector; explicit hybrid and opt-in auto are supported. RGB and
   nonopaque image alpha require hybrid. Policy decisions carry reason codes.
4. The optional publication profile transforms physical layout and render
   configuration while preserving normalized scientific data.
5. The renderer produces a deterministic PGFPlots plan: standalone TeX and,
   where required, image-only PNG assets. It cannot inspect graphics handles.
6. The workflow writes products, compiles with LuaLaTeX in temporary staging,
   and checks PDF existence, nonempty content, and header. Scientific visual
   correctness is additionally tested by development validation, not proved
   by that minimal runtime PDF check.

`m2t.exportSet` adds entry preflight, option inheritance, failure aggregation,
and a schema-1 manifest. Each figure still passes through `m2t.export`.
The inherited `matlab2tikz(...)` implementation remains a separate API.

## Diagnostics and lifecycle

Unsupported semantics produce explicit structured diagnostics, never a legacy
fallback or whole-figure screenshot. Workflow results include success/status,
capability, products, backend decisions, diagnostics, and stage timings.
The analysis and planning stages precede output creation. Tests check that
reader/export calls preserve the source figure. Existing products and asset
directories are protected by default; `Overwrite=true` authorizes replacement
under the documented output lifecycle. See [workflow](docs/WORKFLOW.md) and
[figure sets](docs/FIGURE_SETS.md).

## Determinism and compatibility

FigureIR version 2 supports version-1 JSON migration and documented additive
defaults for older v2 documents. Semantic reinterpretation requires a schema
decision; M7.1 will formalize the complete compatibility contract.
Repeated equivalent inputs/configuration are tested for IR, TeX, planner,
asset naming, and manifest determinism. PNG bytes are compared within the same
encoder; normalized pixels/channels define the cross-encoder semantics.
Runtime timings, absolute result paths, and compiled PDF metadata are not
promised to be identical across machines. No silent data reduction is allowed.

## Architecture decisions and checks

- [Reader/IR/renderer boundary](docs/adr/ADR-0002-normalized-intermediate-representation.md)
- [Schema evolution](docs/adr/ADR-0003-ir-schema-evolution.md)
- [Layout and geometry](docs/adr/ADR-0005-layout-and-geometry.md)
- [Figure-element ownership](docs/adr/ADR-0006-figure-element-ownership.md)
- [Public export workflow](docs/adr/ADR-0007-scientific-export-workflow.md)
- [Profiles](docs/adr/ADR-0008-publication-profiles.md)
- [Figure sets](docs/adr/ADR-0009-figure-set-workflow.md)
- [Hybrid images](docs/adr/ADR-0011-hybrid-image-backend.md)
- [Backend planner](docs/adr/ADR-0012-image-backend-planner.md)
- [Rich scatter](docs/adr/ADR-0020-rich-scatter-semantics.md)
- [Rich image/alpha](docs/adr/ADR-0021-rich-image-alpha-semantics.md)
- [Fixed tiled layouts](docs/adr/ADR-0022-fixed-tiled-layout-semantics.md)

The architecture, profile, set, hybrid, planner, and validation invariants run
in the `repository-policy` CI job. [Testing](test/README.md) explains the
separate native-runtime, portable semantic, compilation, and visual evidence.
