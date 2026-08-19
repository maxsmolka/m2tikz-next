## Summary

Describe the user-visible change and its scientific-export motivation.

## Validation

- [ ] Tests were added or updated for changed behavior.
- [ ] `./test/runPublicPreviewValidation.ps1` passes, or limitations are explained.
- [ ] `git diff --check` passes.
- [ ] Documentation and support boundaries were updated where needed.

## Architecture

- [ ] The renderer remains graphics-handle-free.
- [ ] Runtime-specific behavior remains reader-side.
- [ ] IR/schema changes include migration and validation implications.
- [ ] Unsupported behavior produces explicit diagnostics rather than silent data loss.

## Compatibility

- [ ] MATLAB-validation implications are documented.
- [ ] No MATLAB support claim is based only on Octave results.
- [ ] Generated `.audit/` output and machine-specific paths are excluded.
