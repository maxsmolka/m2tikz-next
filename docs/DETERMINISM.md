# Determinism and numerical representation

Reproducibility applies to equivalent resolved scientific input, explicit
configuration, ordered objects and a stated implementation/runtime boundary.
It is not a promise that different MATLAB/Octave default palettes, automatic
limits, font engines or PDF encoders produce identical bytes.

| Product | Contract and boundary |
| --- | --- |
| FigureIR | Handle-free semantic state and explicit ownership/order. Repeated reads of unchanged supported figures are equal; runtime defaults may differ across environments. Render/profile operations do not mutate input IR. |
| JSON | Repeated `jsonencode` of the same ordered normalized structure is stable in the observed runtime. Deserialization normalizes known versions/defaults. Arbitrary field insertion order and cross-runtime JSON byte identity are not a general canonicalization promise; M7.1 defines compatibility separately. |
| TeX | Equivalent IR/configuration and relative asset stem produce deterministic text, stable object/color/class names and preserved row/sample order. No incidental timestamp, UUID, temporary directory or absolute output root is embedded. Caller-supplied text remains intentional content. |
| Backend planner | Validated IR and versioned policy determine selected backend and reason. Explicit choice wins; auto gives alpha precedence over RGB, then scalar size. No timing/resource-dependent fallback. |
| Diagnostics | Ordered traversal produces stable codes/order for unchanged inputs. Exact message wording is not frozen. Runtime error messages and explicit user-selected paths can occur in returned diagnostics/logs, not in the scientific manifest. |
| Assets | Visible image traversal determines `image-0001.png`, etc.; TeX/manifest references are relative. Quantized RGB/alpha arrays are deterministic and source pixel dimensions are retained. |
| PNG | Same encoder/runtime/settings and RGBA produce repeatable bytes; `tIME` metadata is removed. Across encoders/versions, compare decoded quantized channels, not compression/palette bytes. |
| Figure-set manifest | Ordered caller entries, statuses, effective options, policy reasons and relative product/asset names. No runtime timings, absolute roots, message text or incidental timestamps. Successful, failed and skipped records are tested across output directories. |
| Results, logs and PDF | Timings, absolute caller-selected result paths, compiler logs and compiled PDF metadata are not byte-determinism guarantees. Scientific TeX/assets/manifests are the reproducibility products. |

## Number precision

The established TeX representation remains **15 significant decimal digits**,
with decimal point, canonical zero and lowercase `nan` gap tokens. Locale
normalization is explicit. Buffered image serialization uses the same format
as scalar serialization; no lower-precision fast path is introduced.

This is not a binary-double archive: `1 + eps` can serialize as `1`. Near the
maximum finite double, rounding `realmax` to 15 digits produces
`1.79769313486232e+308`, which parses as infinity in a binary-double reader.
Do not use exported TeX to reconstruct arbitrary extreme scientific doubles.
PGFPlots/TeX also has its own finite numerical range; successful IR validation
is not a guarantee that every extreme scale compiles. Compiler failure is
reported without reducing or replacing the data. Preserve original source
data and normalized IR for analysis and archival purposes.

M6.8 deliberately preserves this existing text contract rather than changing
precision as a side effect of a performance optimization. A future precision
change requires a separate compatibility/fidelity review and representative
TeX-engine tests. Hybrid PNG retains the distinct documented 8-bit channel
boundary; see [large-data contract](LARGE_DATA.md).

## Ordering and layouts

Native child traversal, explicit tiled cells, dual-Y ownership and legend
links remain semantic order, not arbitrary sorting opportunities. Single
scatter3 depth sorting preserves equal-depth input order and permutes all point
roles together. Object/class/asset names derive from stable traversal indices.
Repeated native tests cover tiled layouts, dual Y, rich scatter/images and
supported 3-D; portable foundation suites separately cover their IR contracts.

## Measured optimization and tests

M6.6 identified scalar vector-image serialization as a bottleneck. M6.8 buffers
one source row per numeric formatting call, retaining exactly the previous
TeX bytes, NaNs, scalar values, mapped indices and row/column order. It avoids
one dynamically appended cell and four formatter calls per image pixel.
There is no resampling, raster fallback, precision reduction or changed
backend decision. Other paths are not optimized without relevant evidence.

`runM68DeterminismTests` checks numeric/reference bytes, precision limits,
IR/JSON/TeX stability, planner/assets, PNG encoding, diagnostics and native
repeat reads. `runM68DeterminismWorkflowTests` uses a real compiler for repeated
same-directory and cross-directory sets, relative manifests, unchanged source
state and failed/skipped records. MATLAB adds native tiled/dual/3-D entries;
that does not imply native Octave parity for those families.

Benchmarks report observations, not CI timing thresholds or universal speed
guarantees. See the [M6.8 report](../M2TIKZ_NEXT_M6_8_DETERMINISM_PERFORMANCE_HARDENING_REPORT.md)
for before/after measurements and exact-byte checks.
