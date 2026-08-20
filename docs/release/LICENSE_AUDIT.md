# License audit

## Scope and evidence

This is a repository inventory, not legal advice. The initial inventory was
performed at the M2.4A tag base `m2t-2.0-m2.3` and rechecked against the 0.5.0
release candidate. It records only what repository files and retained history
support.

## Original project and repository

- Project: matlab2tikz
- Repository: `https://github.com/matlab2tikz/matlab2tikz.git`
- Inherited current license file: root `LICENSE.md`
- Preserved authorship record: root `AUTHORS.md` and Git history

## Inherited license

`LICENSE.md` contains the text commonly identified as the two-clause BSD
license: source and binary redistribution with or without modification are
permitted subject to retention/reproduction of the copyright notice, conditions,
and disclaimer. The file does not carry an SPDX identifier or an explicit
license title, so the exact text remains authoritative.

The exact root notice is:

```text
Copyright (c) 2008--2016 Nico Schlömer
All rights reserved.
```

`src/private/m2tUpdater.m` separately embeds the same license conditions with:

```text
Copyright (c) 2012--2014, Nico Schlömer <nico.schloemer@gmail.com>
```

Neither notice may be removed or rewritten during modernization.

## Retention and attribution requirements evidenced by the license

- Source redistributions retain the copyright notice, conditions, and
  disclaimer.
- Binary redistributions reproduce those items in documentation and/or other
  materials.
- `LICENSE.md`, the embedded updater notice, `AUTHORS.md`, `NOTICE.md`, and the
  provenance-bearing Git history are therefore publication-critical.
- Existing historical author and contributor information must not be recast as
  m2tikz-next maintenance or endorsement.

## Additional files reviewed for the public tip

- `test/suites/private/herrorbar.m` attributed code to external authors and said
  it was based on MATLAB's `ERRORBAR`, but contained no explicit license grant.
  No current test or source referenced it, so M2.4B removed it from the current
  tip without rewriting history.
- `logos/` contained an unreferenced inherited SVG without a separate
  asset-license or provenance notice. M2.4B removed it from the current tip
  without assuming that the software license resolved independent asset status.
- Generated `.audit` PDFs, TeX, PNGs, and logs may incorporate tool output or
  fixture content. Their presence in history is documented by the artifact
  policy; no independent license grant was inferred.
- Historical changelog email addresses and author emails are attribution data,
  not m2tikz-next contact addresses.

## Included inherited references reviewed for 0.5.0

- `test/private/calculateMD5Hash.m` is an inherited upstream test helper. Its
  comment credits a faster file-digest approach to Jan Simon's DataHash entry;
  no DataHash package or binary is vendored. The retained history shows the
  helper entering through upstream contributions, but this repository does not
  independently establish the exact reuse boundary.
- `test/suites/ACID.m` is the inherited upstream compatibility suite. Several
  comments identify examples adapted from public MathWorks documentation. No
  external image, archive, or binary asset is included with those cases.
- Modern fixtures and examples use deterministic synthetic data. The stored
  `test/fixtures/ir/line-v1.json` is a generated project fixture required for
  schema migration tests.
- MATLAB, GNU Octave, TikZ/PGF, PGFPlots, TeX Live, Poppler, Python validation
  libraries, and Actionlint are external tools or dependencies referenced by
  documentation/CI; their distributions are not vendored in the release tree.

## Human review required

Before publication, a human should confirm the exact-text BSD-2-Clause
identification and the final attribution wording. The uncertain third-party file
and logo asset are no longer present at the candidate tip; their decision record
is `THIRD_PARTY_REVIEW.md`. Human review should also confirm the disposition of
the two included inherited test references above. No obvious conflicting
license or release blocker was found in this repository review, but that is not
a legal conclusion.
