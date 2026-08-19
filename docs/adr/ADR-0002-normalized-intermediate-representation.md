# ADR-0002: Normalized intermediate representation

- Status: Accepted for the M2 prototype
- Date: 2026-08-08
- Scope: experimental 2-D line path only; no legacy API change

Schema note: ADR-0003 advances the normalized schema to version 2 while retaining
this reader/IR/renderer boundary and a version-1 JSON migration.

## Context

The legacy exporter mixes graphics-handle traversal, runtime compatibility,
normalization, and TeX generation. That coupling makes renderer tests dependent
on a graphics runtime and makes it difficult to establish whether a difference
originates in figure interpretation or serialization. M2 needs a narrow
architecture experiment before any broader migration is considered.

## Decision

Introduce a versioned, normalized, data-only IR between a handle-aware reader and
a handle-free PGFPlots renderer. Version 1 contains a figure, an ordered cell
array of 2-D axes, and ordered line series. Axes own an ordered stable ID, limits, scales, literal
labels/title, grid flags, and series. A line owns paired x/y vectors, RGB color,
line width/style, marker/size, and display name.

The reader is the compatibility boundary. It performs all `get`/`allchild`
operations and converts MATLAB/Octave vocabulary to canonical values. It turns
any point with a non-finite x or y coordinate into a paired `NaN` gap. The IR
validator rejects `Inf`, unknown kinds/versions/enums, malformed dimensions, and
non-normalized colors. Unsupported graphical content fails at the closest reader
boundary with identifier `M2T2:E001:UnsupportedObject` and a stable message that
contains `M2T2-E001 UnsupportedObject`, object type, and structural path.

The renderer accepts only validated IR, never receives handles, and never calls
`get`. It emits deterministic inline coordinates using `%.15g`, explicit axis
options, `unbounded coords=jump`, and normalized style mappings. Locale-specific
decimal commas are defensively replaced. The prototype deliberately retains every
input point.

The experimental entry point is `m2t2.export`. The public legacy
`matlab2tikz` entry point and implementation remain untouched.

## Alternatives considered

### Continue patching the legacy monolith incrementally

This is lowest-risk for isolated compatibility defects, but it does not create a
testable renderer boundary or a serializable contract. It remains appropriate
for legacy maintenance, not for proving the 2.0 architecture.

### Render directly from handles in a second exporter

This would reduce initial code but preserve the central coupling. Renderer-only
tests, JSON replay, and stable normalization contracts would remain impossible.

### Reuse legacy internal structs as the IR

Legacy structs are implementation state rather than a versioned contract. Their
shape can include handle-derived and renderer-derived concerns and would make the
prototype dependent on undocumented legacy behavior.

### Put raw runtime property values into the IR

This merely moves compatibility branches downstream. Canonical enums, RGB, row
vectors, literal text, and paired gap coordinates make the renderer small and
runtime-independent.

### Use JSON as the in-process representation

JSON is useful as an interchange experiment but adds encoding overhead and loses
native shape information. Native structs/cells are the in-process IR; JSON is a
validated serialization of that same contract.

### Replace matlab2tikz in one complete rewrite

A full rewrite would maximize design freedom but remove the working reference
path and multiply compatibility risk before the IR boundary is validated. The
vertical slice provides evidence first and preserves incremental migration or
rejection as real options.

## Consequences

Reader and renderer tests can now fail independently, and a hand-built or JSON
IR can reproduce renderer behavior without a graphics runtime. The cost is an
explicit schema and validator that must evolve deliberately. Adding a field or
changing normalization semantics requires a version decision, fixtures, and
reader/renderer tests.

Version 1 does not model subplot geometry, secondary axes, annotations, custom
ticks, arbitrary interpreters, line alpha, or non-line plot types. Multiple axes
are representable in order, but the prototype renderer rejects them explicitly
with `M2T2:E006:UnsupportedLayout` because layout is outside the M2 line
milestone. Such gaps are not silently approximated: unsupported source objects
fail, while absent schema capabilities remain out of scope until a later IR
version or compatible optional field is designed.

## Migration boundary

This ADR authorizes only a parallel experiment. A production migration requires
MATLAB validation, broader object coverage, an agreed schema-evolution policy,
and evidence that semantic/visual fidelity and performance are acceptable. No
legacy code should consume the IR, and no M2 code should be routed through the
public legacy API during this phase.
