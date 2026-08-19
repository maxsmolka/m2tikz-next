# Historical security review

## Finding

An old Travis CI configuration in preserved upstream history contained a
HipChat notification credential candidate. The value is not reproduced here.

- It was inherited from upstream history and was not introduced by m2tikz-next.
- The notification configuration has been removed from the current tree.
- The targeted current-tree scan found no live-secret pattern.
- Upstream history is intentionally preserved for attribution and provenance.
- Repository evidence does not show that the historical value is currently used.
- No new evidence indicates a currently valid credential.

## Disposition

**ACCEPT PRESERVED UPSTREAM HISTORY**

This disposition is limited to the available repository evidence. It does not
assert that an external service performed revocation, and it must be revisited if
new evidence suggests current validity or security relevance. No automatic
history rewrite is authorized by this review.
