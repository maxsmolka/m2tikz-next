# Versioning policy

m2tikz-next uses Semantic Versioning for public repository releases. The first
public release is version `0.5.0`. Its corresponding tag is `v0.5.0` and is
created only after the release pull request is merged and explicitly approved.

## Pre-1.0 interpretation

- `0.x` means the public API, diagnostics, manifests, and schemas may still
  change as evidence and use cases develop.
- A minor version (`0.x.0`) marks a meaningful user-visible feature or support
  milestone.
- A patch version (`0.x.y`) contains compatible bug, documentation, packaging,
  or validation fixes within the stated minor-version contract.
- `1.0.0` will require an explicit stable API and support commitment; it is not
  implied by broad workflow usability.

Version `0.5.0` means a usable scientific-export preview/beta with a
functional broad core workflow, known unsupported MATLAB graphics, and no
pretense of production-complete 1.0 maturity.

## Independent version domains

The current release is the
[0.8.0 feature-freeze / pre-1.0 acceptance release](FEATURE_FREEZE_0_8_0.md),
identified by the immutable annotated tag `v0.8.0`. Citation and latest-release
metadata use 0.8.0; historical 0.5.0 records retain their original version.
Like the 0.5.0 preview, 0.8.0 is marked as a GitHub pre-release; it is not a
1.0 stability or production-completeness claim. GitHub-generated source
archives are used, without generated local validation artifacts.
After this release, no new major graphics family is planned before 1.0
unless real external acceptance exposes a critical gap that cannot be deferred.
The general pre-1.0 flexibility above does not override the API-freeze
exception/ADR/migration requirements or authorize unrelated feature expansion.

The repository release, FigureIR schema, deterministic manifest schema, and
internal implementation namespace evolve independently. A schema version is
not a repository release number. The public entry points are `m2t.export` and
`m2t.exportSet`; `m2t2.*` remains internal/experimental and has no separate
public version promise.

Inherited matlab2tikz tags identify original upstream history. New public
m2tikz-next releases use ordinary `vMAJOR.MINOR.PATCH` tags only when an actual
release is approved.
