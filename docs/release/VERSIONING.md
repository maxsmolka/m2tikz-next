# Versioning policy

## Recommendation

The first public preview should use:

```text
v0.1.0-preview.1
```

This is a SemVer-compatible prerelease that communicates an unstable public API
and distinguishes public m2tikz-next versions from inherited matlab2tikz releases
and internal architecture tags.

Do not create this tag in M2.4A. Tag it only after M2.4B documentation, CI,
publication review, and a clean reproducible validation run.

## Tag classes

- inherited tags (`0.x`, `1.0.0`, `v1.1.0`, and similar) identify original
  matlab2tikz history;
- `m2t-2.0-*` tags identify internal modernization milestones;
- future `v0.x.y-preview.n` tags identify m2tikz-next public previews;
- a stable `v1.0.0` requires explicit API/support commitments and is not implied
  by the experimental IR version number.

The IR schema version, repository release version, and experimental namespace
name evolve independently. `m2t2.export(...)` remains experimental through the
first preview; `matlab2tikz(...)` remains the inherited legacy API.
