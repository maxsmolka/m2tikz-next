# Synthetic FigureIR compatibility goldens

Each short input JSON intentionally exercises one supported compatibility
class. Its `.canonical.json` partner records normalized v2 output from the
internal deterministic codec. All data and labels are synthetic/public-safe.
Do not regenerate expected files automatically when tests fail: review the
semantic change, schema policy and exact byte diff first.

The nine pairs cover old/rich scatter, old/rich image-alpha, tiled layout,
dual Y, scientific 3-D, optional bar/background semantics and line gaps.
The separate unchanged `../line-v1.json` remains the historical migration
fixture. Contract tests additionally mutate fields for negative/default/order/
numeric-edge coverage. See [FigureIR contract](../../../../docs/FIGURE_IR.md).
