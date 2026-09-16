# ADR-0025: FigureIR compatibility and deterministic JSON

Status: Accepted

## Context

FigureIR v2 accumulated rich scatter/images, fixed layouts, dual rulers and
bounded 3-D without incompatible reinterpretation. ADR-0003 requires safe
defaults and explicit semantic fields, but the JSON loader also accepted
malformed missing payloads and migrated arbitrary v1 kinds as lines. Raw JSON
encoding loses a single NaN to empty data in both tested runtimes; Octave's
encoder additionally corrupts observed extreme doubles. A credible persistence
contract cannot silently turn those cases into different scientific content.

## Decision

Retain schema v2, with backward-readable optional additions and no promised
forward understanding of new node kinds. Define the exact contract in
[FIGURE_IR.md](../FIGURE_IR.md). Unknown fields are opaque optional extension
data, not permission to hide required semantics. Unknown kinds fail.

Enforce required identity/payload/ownership fields at loading, validate after
normalization, and restrict v1 migration to its supported line schema. Preserve
the existing generated-series-ID normalization as an explicitly named legacy
exception to ADR-0003; axes IDs and owners are never guessed. Preserve provided
scatter colors rather than overwrite them when applying old mode defaults.
Owner kind/ID and annotation payloads must be complete. Preserve ArrowIR `end`
on Octave by disabling its JSON field-name rewriting; reject nonportable
extension keys instead of silently renaming them. Nondefault arrow endpoints
are regression-tested, not only the constructor defaults.

Add internal `toJson` with lexical keys, ordered arrays, explicit numeric shapes
and 17-digit finite numbers. Encode scalar NaN as `[null]`; reject ambiguous
bare null in the loader. Empty data remains `[]`. Existing unambiguous v1/v2
JSON remains readable. This is an internal persistence helper, not a new public
workflow, not a new TeX precision policy and not a manifest format change.

No schema bump is needed: supported scientific types, meanings, owners and
ordering are unchanged. Rejected inputs were malformed/ambiguous or outside
the named migration, contrary to the prior documented schema contract. Numeric
JSON nesting expresses the existing matrix/vector values; it does not add a
tagged alternate semantic representation. An incompatible future semantic or
required-field change does require a new version and migration decision.

## Migration guidance and consequences

Internal persistence callers should replace raw `jsonencode(ir)` with
`m2t2.ir.toJson(ir)`. Already ambiguous null/extreme-number files cannot be
recovered by guessing: regenerate from source or explicitly recover original
values and intended shapes. No automatic disk rewrite is performed.

Canonical bytes are bounded to a codec implementation and normalized data,
with committed ASCII golden pairs checked in MATLAB and Octave. Broader codec
version/Unicode differences remain explicit. Unknown metadata must be JSON-safe
data; native objects are rejected. This serializer is not optimized for large
archival arrays and has no timing/memory guarantee. Public rendering does not
call it, so no export performance regression or public API break is introduced.

Schema, semantic replay, exact golden bytes and real PDF compilation are
separate tests. Native reader validation remains independently required for
newly claimed graphics support; M7.1 introduces no such family.
