# ADR-0003: IR schema evolution

- Status: Accepted
- Date: 2026-08-09
- Scope: serialized and in-memory `m2t2` intermediate representation

## Context

M2 introduced a version-1 JSON-capable line IR. M2.1 needs explicit text,
ticks, axes direction/box, legend ownership, common series fields, scatter, and
errorbar. Stored IR must remain replayable, while schema versions must still tell
consumers when old assumptions are unsafe.

## Decision

The schema version describes semantic compatibility, not the number of releases
or fields. A change is backward-compatible when an older document remains valid
and retains its prior meaning under documented defaults. Examples are a new
optional field with a semantics-preserving default, optional metadata ignored by
an older renderer, or a new discriminated series kind that existing nodes do not
need to adopt. Such changes keep the current version.

A change is breaking when it removes or renames a field, changes a field's data
type or meaning, changes a default that affects rendering, makes previously valid
data invalid, or reinterprets ordering/ownership. Breaking changes increment the
version. New versions require an explicit migration or an explicit unsupported-
version diagnostic; silent guessing is forbidden.

M2.1 defines **IR version 2**. Replacing label/title and `displayName` strings
with `TextIR` changes their data type. Moving legend visibility and entry order
out of `displayName` also changes default ownership. These are breaking changes,
so retaining version 1 would make the version field misleading.

The loader accepts stored version-1 JSON and migrates it in memory to version 2:

- string text becomes `TextIR(value, plain)`, matching the v1 renderer's literal
  escaping;
- axes direction becomes `normal`, ticks remain `auto`, and box becomes `on`,
  matching the prior PGFPlots output contract;
- line series gain stable IDs and `visible=true`;
- non-empty v1 display names create an automatic visible legend, preserving the
  v1 renderer's behavior.

The committed `test/fixtures/ir/line-v1.json` stays unchanged as the compatibility
fixture. New serialized artifacts use version 2. Migration output is validated
before rendering and is never written back over its source implicitly.

## Compatibility rules

For version 2, absent optional fields are filled only by constructors documented
as schema defaults. Required discriminators, IDs, coordinate data, and semantic
owners are not inferred except during a named version migration. Unknown versions
fail with `M2T2:E008:UnsupportedIRVersion`; malformed current IR fails with
`M2T2:E003:InvalidIR`.

Every schema change must add tests for direct IR, JSON roundtrip, the oldest
supported stored fixture, and deterministic rendering. A future version may drop
a migration only through a separately documented support-window decision.

## Consequences

The version now communicates real compatibility, old JSON remains usable, and
optional evolution does not cause needless increments. The costs are explicit
migration code, fixtures retained across releases, and discipline around defaults.
Consumers must dispatch on both schema version and series `kind` rather than
assuming every series is a line.
