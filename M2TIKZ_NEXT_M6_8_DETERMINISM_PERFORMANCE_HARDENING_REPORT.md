# M6.8 - Determinism and performance hardening

## Baseline and scope

Started from clean public main `02622f6765d971e33568cfeaaa6454bd1840f0a4`
after M6.7 PR #11. Exact head `42c5d79e4ee79bb6ad6d54866c93669b75ca44b3`
passed all three required jobs in hosted run 35079046793 before merge. The
M6.7 branch was removed locally/remotely and ancestry/clean state verified.
This phase uses `m6.8/determinism-performance-hardening`; release stays 0.5.0.

Scope is deterministic products and an evidenced serialization bottleneck,
not new graphics support, reduction, public options or altered scientific
semantics. [DETERMINISM.md](docs/DETERMINISM.md) records the audited boundaries.

## Audit

- FigureIR: stable runtime traversal and handle-free explicit ownership/order;
  unchanged supported figures produce equivalent repeated reads. Profiles and
  renderers preserve input IR. Native tiled/dual/3-D repeated sets are tested.
- JSON: repeated ordered normalized structures are stable in the observed
  runtime. Arbitrary insertion-order/cross-runtime canonical JSON is not
  promised by raw `jsonencode`; M7.1 defines that compatibility boundary.
- TeX/plans: stable class/color/object names, sample/cell ordering, deterministic
  planner decisions/reasons and relative image asset names. No random/time/path
  metadata is introduced. Source-provided text is intentional content.
- Diagnostics: deterministic first failure and code/order for identical input;
  exact messages and runtime/compiler logs are not frozen byte products.
- Manifests: stable caller order, relative paths and effective policy/status
  metadata, including failed/skipped entries. Timings, message text and absolute
  output roots are excluded. Root relocation does not change product bytes.
- PNG: repeated same-encoder RGBA bytes and absence of tIME metadata are checked.
  Cross-encoder equivalence concerns decoded quantized channels, not compression
  or palette bytes. PDF metadata/result paths/timings remain outside byte claims.
- Locale: the focused suite passes in the normal environment and a generated
  `de_DE.utf8` environment whose decimal-point query returns comma. The emitted
  portable TeX fixture is byte-identical across those environments.

## Precision review

The existing 15-significant-digit TeX format is retained, including canonical
zero, decimal point and lowercase NaN gaps. No precision is reduced for speed.
Tests compare buffered output against scalar formatting across tiny/large
values, NaNs, signed zero and direct integer image data with fractional axes.
Integer data is explicitly converted before assembling the mixed numeric
buffer, preventing MATLAB integer concatenation from truncating coordinates.

The review makes two existing limits explicit: `1 + eps` can format as `1`,
and rounded `realmax` can parse beyond the finite-double maximum. Textual TeX
is not an archival binary-double representation; TeX-engine numeric range is
also bounded. Original scientific values remain in IR. Compiler failure never
triggers reduced/replaced data. This phase does not change precision as an
incidental optimization; future precision changes need separate fidelity and
compatibility review. PNG's existing 8-bit channel boundary is distinct.

## Measured optimization

M6.6 identified scalar vector-image serialization as the main measured render
bottleneck. Previously it appended one cell and invoked four scalar formatters
per image pixel. The new implementation formats one bounded source-row buffer,
preserving the exact row/column order, scalar metadata, mapped indices, NaNs
and every previous TeX byte. No other renderer is optimized speculatively.

Native measurements use MATLAB R2026a Update 5 on Windows with identical full
synthetic fixtures before and after. Wall times are combined plan/render stage
observations, not statistical guarantees or CI thresholds.

| Scalar vector image | Cells | Before seconds | Final after seconds | TeX bytes unchanged |
| --- | ---: | ---: | ---: | ---: |
| 512 by 512 | 262144 | 3.7939085 | 0.2601541 | 7149478 |
| 1024 by 1024 | 1048576 | 17.8977784 | 0.9704850 | 28867497 |

An earlier post-change run observed 0.2361839 and 1.0019513 seconds respectively,
showing ordinary timing variability. No peak-memory claim is made. Before/
final-after hashes match for **all ten full benchmark TeX files and all four
PNG assets**, including 100k line/scatter, scalar/RGB images and the 129-square
surface. Sample/pixel cardinality and source IR are verified by the benchmark.
Full million-cell vector TeX compilation remains deliberately unclaimed, as
in M6.6; small representative matrix tables use real compiler validation.

## Evidence and gates

Validated with MATLAB R2026a Update 4 on Windows.

That historical evidence wording is retained. New native evidence is Update 5
on Windows. Real native workflow compilation uses Linux LuaLaTeX / TeX Live
2025/Debian through a temporary bridge, not a claimed native Windows compiler.

| Layer | Result |
| --- | --- |
| Focused deterministic/reference tests | 8/8 in MATLAB and Octave, including precision, integer coordinates, PNG, diagnostics and IR/TeX/JSON |
| Foreign-locale focused tests | 8/8 in Octave under generated German locale; normal/German TeX bytes identical |
| Real repeated/cross-root workflows | 5/5 in each runtime: MATLAB five native figures, Octave two common figures; final native rerun passed |
| Full native benchmark | Ten full fixtures before/after; all ten TeX and four PNG products byte-identical |
| Full portable regression | Final complete rerun passed after integer-coordinate and Octave NA guards; process exit zero |
| Visual evidence | Five native workflow PDFs inspected: image alpha, repeated line coordinates, fixed cells, dual rulers, equal-depth scatter3 ties; known 3-D viewport limitations unchanged |
| Static gates | Six architecture invariants, documentation links, confidentiality, citation and actionlint passed; staged checks required before commit |

The portable baseline remains 140 core, 235 extended, eight curated PDFs,
nine rich-scatter and eleven rich-image TeX cases, with all accumulated
foundation suites and the new eight-plus-five deterministic checks. Runtime,
portable, encoder, compiler and visual evidence are not collapsed into an
unsupported cross-runtime parity claim. No wall-clock CI threshold is added.

## Acceptance decision

Focused, full portable, native and byte-comparison evidence pass. Exact-head
hosted `repository-policy`, `octave-tests`, and `tex-preview` success remains
required before merge. M7.0 begins only after merge verification,
fast-forward, phase-branch cleanup and a clean working tree.
