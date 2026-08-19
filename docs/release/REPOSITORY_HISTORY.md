# Repository history policy

m2tikz-next intentionally retains the complete inherited matlab2tikz Git
history. The expected lineage is:

```text
upstream matlab2tikz history
  -> architecture and validation modernization commits
  -> m2tikz-next preview and product development
```

The repository must not be squashed into a new initial commit. Preserved history
supports attribution, provenance, audits, regression archaeology, and exact
traceability of inherited versus modernization work.

Development tags such as `m2t-2.0-m1b`, `m2t-2.0-m2`, and `m2t-2.0-m2.3` remain
historical architecture markers. They are not public semantic-release versions.
No history rewrite is authorized by this policy; any publication-sensitive
historical finding must be reviewed explicitly before such an exceptional action
is considered.

## Intended future remotes

M2.4A does not change remotes. At inspection time, `origin` still points to the
official matlab2tikz repository. The intended future state is:

```text
origin   -> user's future m2tikz-next repository
upstream -> https://github.com/matlab2tikz/matlab2tikz.git
```

Configure this only after the new repository exists and has been reviewed. Do
not push to the current `origin` as part of publication preparation.
