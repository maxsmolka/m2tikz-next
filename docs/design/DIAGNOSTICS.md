# Structured diagnostics concept

## Current behavior

The exporter currently mixes `error(identifier, ...)`, `warning(identifier, ...)`,
and `userWarning(m2t, ...)`. Some warnings have stable MATLAB identifiers, others
are plain messages, and `userWarning` also reflects the `showWarnings` option.
Callers therefore cannot consistently filter, collect, or turn a category into an
error. A few fallback paths intentionally continue after reporting unsupported
objects; other paths throw immediately.

## Proposed model

A diagnostic is a small record with a stable code, severity, human-readable
message, object type/handle context where safe, and an optional cause. Initial
codes should include:

- `M2T-W001 UnsupportedObject`: an object or property cannot be represented and
  is skipped or approximated.
- `M2T-W002 EngineCompatibility`: valid output needs a particular engine,
  package, font, or encoding policy.
- `M2T-E001 ExportFailed`: export cannot produce a complete, trustworthy result;
  the original exception is retained as its cause.

Codes are part of the compatibility contract; prose may improve without breaking
automation. Severity is not inferred from the `W`/`E` character alone in code,
but the naming makes logs readable.

## Compatibility path

The first implementation should introduce one internal emission function that
maps records back to today's warning/error behavior and honors `showWarnings`.
Collection or callbacks can be added later through an explicit API. Existing
identifiers should be mapped and deprecated deliberately, not globally replaced.
Catch blocks must only translate understood failures and must preserve causes;
unknown programming errors must not be hidden. Tests should assert codes and
context rather than full prose, with MATLAB and Octave coverage.

M1A defines this contract only. It does not change runtime diagnostics.

## Rich-scatter reader diagnostics

M6.1 assigns focused, stable failures before normalized IR is constructed:

- `M2T2:E040:MalformedScatterData` — X/Y are empty, malformed, unequal, or nonfinite.
- `M2T2:E041:UnsupportedScatterSize` — `SizeData` is not one finite nonnegative
  area or one such area per point.
- `M2T2:E042:UnsupportedScatterColor` — active `CData` is neither constant RGB,
  N-by-3 RGB, nor N finite scalar values.
- `M2T2:E043:UnsupportedScatterTransparency` — edge or face alpha is not the
  opaque scalar value one.
- `M2T2:E044:UnsupportedScatterMarkerStyle` — marker edge/face ownership cannot
  be represented by the narrow `none`, `flat`, or constant-RGB contract.
- `M2T2:E045:UnsupportedScatterDimensionality` — a scatter has nonempty ZData.
- `M2T2:E046:UnsupportedScatterColorMapping` — scalar point metadata depends on
  an unsupported axes color-mapping interaction.

All cases fail rather than dropping points or collapsing size/color arrays.

## Rich-image reader and planning diagnostics

- `M2T2:E047:MalformedImageCData` — empty, nonnumeric, or invalid scalar data.
- `M2T2:E048:UnsupportedImageDimensionality` — CData is neither 2-D scalar nor RGB.
- `M2T2:E049:UnsupportedImageRGB` — RGB class, range, or finiteness is unsupported.
- `M2T2:E050:MalformedImageAlphaData` — alpha shape, class, range, or finiteness is invalid.
- `M2T2:E051:UnsupportedImageAlphaMapping` — alpha is not explicitly unmapped.
- `M2T2:E052:UnsupportedImageColorMapping` — scalar/RGB mapping cannot be preserved.
- `M2T2:E053:UnsupportedVectorRichImage` — forced vector would discard RGB or alpha.
- `M2T2:E054:UnsupportedImageCoordinates` — placement is malformed or ambiguous.

These diagnostics prevent grayscale conversion, alpha loss, resizing, or an
invented RGB colorbar.

## Export security diagnostics

- `M2T:E002:InvalidOutputPath` rejects unsafe/control characters in output bases.
- `M2T:E003:OutputExists` preserves products without explicit overwrite.
- `M2T:E006:UnsafeOutputProduct` rejects redirected products, directory/file
  conflicts, unknown/nested asset content or unavailable safe path inspection.
- `M2T:C005:UnsafeProcessArgument` rejects unsafe compiler arguments.
- `M2T2:E055:UnsafeAssetReference` rejects unsafe relative hybrid asset names.

Figure-set preflight maps product collisions to `M2T:SET_OUTPUT_EXISTS` and
invalid product paths to `M2T:SET_INVALID_OUTPUT`. Message text can include the
caller-selected path; generated scientific TeX does not embed absolute paths.

## Fixed tiled layouts

- `M2T2:E056:UnsupportedTiledLayout`: dynamic/nested/mixed/partial/hidden
  layouts, unsupported spacing/padding, subtitle or shared-label rotation.
- `M2T2:E057:InvalidTileCell`: invalid/out-of-bounds/overlapping tile cells.
- `M2T2:E058:UnsupportedTileDecoration`: outer/multi-tile or ambiguous
  legend/colorbar ownership.

These are analysis-stage unsupported failures, not successful partial exports.
Malformed portable layout metadata also fails IR schema validation. Tiled
profile gutter limitations use `M2T:PROFILE_GEOMETRY_INVALID`.

## Dual Y axes

- `M2T2:E059:AmbiguousDualYOwnership`: a child lacks a unique active-side
  membership, or the runtime legend lacks unambiguous series links.
- `M2T2:E060:UnsupportedDualYState`: unsupported child/ruler presentation,
  non-2-D state or reversed legend presentation.
- `M2T2:E061:InvalidDualYXState`: nonnumeric or inconsistent shared X,
  inconsistent physical/color state, or unsupported manual aspect ratios.

Malformed portable side metadata, unrelated overlays and nonpositive log
domains fail `M2T2:E003:InvalidIR`. Unsupported dense/manual dual-axis profile
geometry uses `M2T:PROFILE_GEOMETRY_INVALID`. No successful partial export is
produced. See [the contract](../DUAL_Y_AXES.md).
