# Portability and environment contract

This contract defines observed environments and explicit limits, not a promise
for every MATLAB version, graphics toolkit, operating system or TeX document.
See [runtime compatibility](RUNTIME_COMPATIBILITY.md), [installation](INSTALLATION.md),
[the API](API.md) and [determinism](DETERMINISM.md).

## Observed environments

Validated with MATLAB R2026a Update 4 on Windows.

That statement is historical. New M7.2/M7.3 evidence uses MATLAB R2026a Update
5 on Windows. MATLAB needs its JVM for safe product-path inspection. The
available local Octave is GNU Octave 11.3 with gnuplot on Linux in a container;
it is not native Windows Octave. Hosted CI uses the pinned GNU Octave 11.3
Linux image and separately provisions TeX. No second MATLAB release, macOS,
alternative Octave toolkit or native Windows TeX installation is established
by these runs.

Local real compilation uses LuaLaTeX / TeX Live 2025 (Debian). Native MATLAB
reaches that compiler through a local process bridge; this proves the Windows
reader/workflow and the observed bridge, not every Windows TeX distribution.
Historical public preview evidence used TeX Live 2026. Hosted TeX packages are
installed from that runner's package repositories; their versions may differ.

## Filesystem and product paths

Relative paths resolve from the caller's current working directory. Absolute
paths and explicit parents are allowed: this API is not a filesystem sandbox.
Use `fullfile` for host paths. Windows forward/back separators are accepted as
host syntax; POSIX backslash is not a directory separator. Do not transplant a
Windows drive path into a Linux process and expect path translation.

Tests exercise spaces, `unicode-äöü`, nested directories, relative and absolute
outputs, image-only PNG assets and figure sets. The user-selected parent and
temporary directories must be writable. Unicode support additionally depends
on the runtime, filesystem and compiler receiving the same path spelling; the
observed umlaut cases do not establish arbitrary network shares or long-path
behavior. Shell/TeX-sensitive stems are deliberately rejected, not escaped into
a broader filename guarantee. Windows also rejects reserved device names,
trailing dots/spaces and unsafe expansion characters. See [API.md](API.md).

Generated TeX refers to assets with relative forward-slash paths under
`<base>-assets/`, protected with `\detokenize`. Move the TeX and its asset
directory together. Figure-set manifests contain relative product/asset names,
not absolute source paths. Set entry names remain the API's safe ASCII names;
Unicode output directories do not expand that separate naming contract.

Product preflight rejects collisions, redirected final products and foreign or
nested asset content. Parent directories are caller-controlled and may be
linked. Overwrite is explicit, not transactional rollback. Serialize writes to
the same output base/set. Failure may leave new TeX/assets and no PDF.

## Encoding, locale and newlines

Workflow-owned TeX, JSON/manifests and text logs are explicitly encoded as UTF-8
without a BOM. The writer performs a lossless encode/decode check before opening
the destination; invalid text fails rather than silently replacing characters.
Empty text remains a valid zero-byte write. Generated templates use LF; binary
writing does not translate LF into platform CRLF. Caller-provided line breaks
inside trusted text are not globally rewritten, and compiler logs retain the
compiler's own content/newlines.

Umlauts, literal TeX-special characters, Greek math (`$\alpha^{2}$`) and canonical
JSON containing a literal Greek character are exercised. Unicode file encoding
does not guarantee that an arbitrary font contains every glyph. A successful
compiler exit and PDF header alone do not establish correct glyph rendering;
visually inspect scientific labels. Literal text uses the `none` interpreter;
TeX/LaTeX-interpreted strings are trusted executable typesetting input.

Scientific numbers use a dot and no localized thousands separators. TeX retains
the established 15-significant-digit contract; canonical FigureIR JSON uses 17
digits. Locale checks remain in the M6.8 suite, with M7.3 fixed-byte numeric
representatives. No unit conversion or locale-dependent numeric formatting is
introduced. See [precision boundaries](DETERMINISM.md).

## Compiler/process contract

The workflow discovers `lualatex` by running its version command on PATH, then
invokes it with quoted arguments, disabled shell escape, nonstop interaction,
halt-on-error and file/line diagnostics. Control characters reject before
discovery; Windows additionally rejects quote, percent and exclamation forms.
POSIX quotes, dollar signs, backticks and backslashes are escaped in the process
layer. Renderers never invoke a process. This is not a sandbox: trusted TeX can
still read files and consume resources; see [security](../SECURITY.md).

Compilation stages files in a temporary directory, establishes TeX input/cache
paths, captures stdout/stderr and restores its environment afterward. Compiler
exit failure yields `M2T:C003:CompilationFailed` with a local log when writable.
Missing executable yields `M2T:C001:CompilerNotFound`. The public workflow then
checks PDF existence, nonempty length and `%PDF` header, with distinct V001,
V002 and V004 diagnostics. These minimal checks are not a full PDF parser.

There is **no built-in process timeout or cancellation option**. A hung compiler
can block the synchronous call. CI/job-level limits and externally supervised
test sessions must enforce time budgets. Do not describe this as bounded-time
execution or silently add a new option to the frozen API. Temporary cleanup is
best effort after abrupt process termination; review local temporary products
before retrying. Concurrent calls must not share an output base.

PNG encoder/open/normalization failures use the existing
`M2T2:E_PNG_WRITE_FAILED` code; completed writes check byte count and close status.
Text write failures use `M2T:E004:WriteFailed`. OS-specific permission details
remain in local diagnostic messages. The deterministic unwritable-target test
uses a file where a parent directory is required, so privileged CI cannot turn
a permission-bit simulation into a false success.

## TeX and cross-environment evidence

Standalone documents require LuaLaTeX, `standalone`, TikZ/PGF and PGFPlots with
the generated compatibility setting (1.18). The project validates generated
standalone figures, not arbitrary journal classes, user preambles, fonts,
package interactions or inclusion into another document. Check `lualatex
--version`, `kpsewhich standalone.cls` and `kpsewhich pgfplots.sty` locally.

| Comparison | Contract and M7.3 evidence |
| --- | --- |
| Scientific semantics | Common synthetic payload and exact decoded RGB/alpha values agree. Native defaults/layouts across runtimes need not be identical. |
| Canonical JSON | Common Unicode/numeric FigureIR has one reviewed SHA-256 golden in both local runtimes; hosted tests require that same value. |
| TeX bytes | The common explicit IR produces one reviewed UTF-8/LF golden; hosted tests require those bytes too. |
| PNG bytes | Stable within the same encoder; MATLAB/Octave files are observed to differ while pixels/alpha agree exactly. |
| PDF bytes | Not required across engines/environments; font subsets, metadata, compression and timestamps may differ. Real compilation and visual checks are separate evidence. |

`runM73EnvironmentTests(out,false)` checks nine core cases. With `true`, it adds
real spaced/Unicode/nested path exports, a figure set and a deliberate compiler
error, and compiles the common portable document. Expected JSON and TeX hashes
are committed in the test, not regenerated by CI. Combined with the preserved
runtime/IR/security gates, this makes external environment failures diagnosable
without inventing a multi-version support matrix.
