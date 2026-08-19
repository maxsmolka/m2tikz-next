# Versioning policy

m2tikz-next uses Semantic Versioning for public repository releases. The
working first public release target is `0.5.0`; no tag is created by this
readiness work.

## Pre-1.0 interpretation

- `0.x` means the public API, diagnostics, manifests, and schemas may still
  change as evidence and use cases develop.
- A minor version (`0.x.0`) marks a meaningful user-visible feature or support
  milestone.
- A patch version (`0.x.y`) contains compatible bug, documentation, packaging,
  or validation fixes within the stated minor-version contract.
- `1.0.0` will require an explicit stable API and support commitment; it is not
  implied by broad workflow usability.

Version `0.5.0` therefore means a usable scientific-export preview/beta with a
functional broad core workflow, known unsupported MATLAB graphics, and no
pretense of production-complete 1.0 maturity.

## Independent version domains

The repository release, FigureIR schema, deterministic manifest schema, and
internal implementation namespace evolve independently. A schema version is
not a repository release number. The public entry points are `m2t.export` and
`m2t.exportSet`; `m2t2.*` remains internal/experimental and has no separate
public version promise.

Inherited matlab2tikz tags identify original upstream history. New public
m2tikz-next releases use ordinary `vMAJOR.MINOR.PATCH` tags only when an actual
release is approved.
