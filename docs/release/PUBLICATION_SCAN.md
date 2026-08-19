# Secret and personal-data scan

## Scope and method

M2.4A inspected the current tree (including hidden files but excluding binary
content from text matching), targeted Git history, CI configuration, reports,
PowerShell runners, and tracked audit evidence. Patterns covered common GitHub,
AWS, Slack, generic token/secret assignments, and private-key headers. Results
are evidence-oriented and do not guarantee that an arbitrary encoded secret
cannot exist.

## Findings

### Historical HipChat notification value

- Location before M2.4A cleanup: inherited `.travis.yml`
- Introduced by upstream commit: `0ee4d87` (`HipChat integration into Travis CI`)
- Classification: likely expired/invalid historical credential candidate tied
  to legacy HipChat CI, but **needs human review** rather than an assumption that
  historical exposure is harmless
- Current-tree action: notification entry removed
- History action: none; history preservation is mandatory
- Required review: confirm that no credential rotation or exceptional history
  treatment is needed before publication

The value itself is intentionally not reproduced in this document.

### Modernization validation paths

- Four tracked PowerShell runners contained an absolute Python path under a
  local Windows user profile.
- Classification: personal/machine-specific path, not a secret.
- Current-tree action: replaced with portable `python` command defaults; related
  Octave, TeX, Poppler, Bash, and benchmark defaults were also made PATH-based.

### Historical audit evidence removed from the current tip

- 30 tracked audit files contained the same local Windows user-profile prefix,
  primarily compiler logs and M2 TSV path fields.
- Classification: benign local username/path disclosure, publication-unfriendly
  but not a credential.
- M2.4B dependency searches and the new clean-state gate found one consumed
  input: a small version-1 JSON migration fixture. It was relocated to
  `test/fixtures/ir/line-v1.json`; no generated `.audit` dependency remains.
- Two non-generated M0 audit/performance source harnesses were retained under
  `benchmarks/`; their generated outputs were not retained.
- Action: all 2,497 tracked `.audit` files were removed from the candidate tip
  using normal Git deletion; milestone reports and source-level validation
  design remain public. History remains intact.

### Email addresses and attribution

Emails occur in the inherited changelog, the separately licensed updater notice,
test-report code, and attributed `herrorbar.m`. They are historical authorship or
fixture data, not m2tikz-next contact information. No personal email was added as
a new project contact.

### Other results

- No current-tree match for GitHub, AWS, Slack, private-key, or common live-token
  patterns after cleanup.
- No private/internal/localhost URL pattern was found in publication source.
- No company-internal information or machine hostname was identified in new
  modernization source outside generated audit evidence.

## Publication gate

The formal historical HipChat disposition is `SECURITY_REVIEW.md`: **ACCEPT
PRESERVED UPSTREAM HISTORY** based on current repository evidence. The candidate
tip contains no tracked `.audit` file or personal machine path. Repeat the scan
after fresh-copy validation and before the first push; do not rewrite Git history
automatically.
