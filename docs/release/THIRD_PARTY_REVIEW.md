# Third-party material review

## `test/suites/private/herrorbar.m`

Repository-wide text and path searches found no current test, script, or product
source that calls or loads this file. Its location and history identify it as an
inherited legacy-test helper. The file attributes external authors and states
that it is based on MATLAB's `ERRORBAR`, but contains no explicit redistribution
license. No license was inferred from that wording.

Because no repository evidence established a redistribution basis and the file
is not required by the modern preview or current inherited test entry points, it
was removed from the current public-preview tip with normal Git deletion. Its
history remains available for provenance. No replacement implementation was
copied.

## `logos/`

The directory contained the inherited `matlab2tikz.svg`. No separate asset
license or explicit provenance statement was found, and no current source,
documentation, test, or build file referenced the asset. Software-license
coverage was not assumed to resolve independent image-asset provenance.

The directory was therefore removed from the current public-preview tip with
normal Git deletion. History remains intact, and M2.4B does not create a new
logo; the preview README is text-only.

## Result

Neither reviewed item is a current test dependency. Their removal does not alter
the scientific export implementation or the retained upstream history.

## Included inherited references

The 0.5.0 review also identified two retained upstream test sources with
explicit external references:

- `test/private/calculateMD5Hash.m` credits a file-digest approach to Jan
  Simon's DataHash entry. The external package is not vendored.
- `test/suites/ACID.m` contains compatibility cases whose comments cite or say
  they were adapted from public MathWorks documentation. No associated external
  asset is vendored.

Both files are classified as inherited upstream material, not newly imported
m2tikz-next dependencies. Retained Git history preserves their upstream
provenance, while the exact reuse boundary is not independently established by
repository-local license text. They remain explicit human-review items for the
release; this inventory makes no legal determination.

Project-authored modern examples and the version-1 JSON migration fixture use
deterministic synthetic data. External runtime and TeX dependencies are
referenced rather than bundled. No tracked image, executable, archive, or
runtime binary is present in the 0.5.0 candidate tree.
