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
