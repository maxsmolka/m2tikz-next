# Security policy

## Reporting a vulnerability

Do not report suspected vulnerabilities, credentials, or sensitive data in a
public issue.

Use GitHub Private Vulnerability Reporting from the repository's **Security**
page. If GitHub does not present the private reporting form, contact the
repository owner through their GitHub profile before sharing details; do not
substitute a public issue or discussion.

## Supported versions

| Version | Security updates |
| --- | --- |
| 0.5.x | Current public preview line |
| Earlier m2tikz-next development versions | Not supported |
| Original matlab2tikz releases | Refer to the upstream project |

Version 0.5.0 is pre-1.0. Security fixes will be evaluated for the current
public minor line; this policy does not promise indefinite maintenance of old
preview versions.

## Release checks

- Verify the enabled private reporting path from the repository Security page.
- Run current-tree confidentiality, secret, and publication-path scans.
- Review security-sensitive dependency and CI changes.
- Keep generated local validation output and credentials out of release
  artifacts.

The inherited Git history is retained for provenance. The historical upstream
CI review is summarized without credential material in
`docs/release/SECURITY_REVIEW.md`.

## Export trust boundary

Export figures, FigureIR and TeX only from trusted sources. MATLAB callbacks,
TeX/LaTeX-interpreted labels, and LuaLaTeX input can execute code or access files.
The compiler explicitly disables shell escape, quotes process arguments and
uses a temporary build directory; this is **not an operating-system sandbox**.
Lua and TeX retain capabilities beyond shell escape. Use an independently
isolated process/container for untrusted documents. `Interpreter='none'` text
is escaped as literal text; `tex` and `latex` intentionally preserve their
documented mathematical markup semantics.

Callers may choose explicit absolute or relative output directories, including
parent-relative paths and linked parent directories. There is no artificial
repository-only output sandbox. Callers must own/trust that directory and must
not allow concurrent adversarial modification during export. Hard links and
filesystem races are not a supported isolation boundary.

Before changing products, export checks `.tex`, `.pdf`, `.compile.log`, the
asset directory and (for sets) `m2t-manifest.json`. Redirected final products
(symbolic links, including dangling links) are rejected. MATLAB uses JVM path
inspection and fails explicitly if no JVM is available; Octave uses `lstat`.
MATLAB also checks canonical final paths to reject redirected directories.
Existing products require explicit `Overwrite=true`; a file product cannot
replace a directory. Asset cleanup is nonrecursive and accepts only flat
generated `image-NNNN.png` names (at least four digits). Unknown files, nested
directories or linked assets fail preflight without deleting earlier products.
Never place unrelated files in generated asset directories.

Stems retain dots, spaces and underscores. Control characters and unsupported
TeX-sensitive stem characters are rejected; Windows additionally rejects device
names, alternate-stream colons and shell-expansion characters. Hybrid image
references are one safe relative directory plus generated PNG names, serialized
with `\detokenize`. Figure-set names remain restricted to their documented
alphanumeric/hyphen/underscore contract. See [workflow](docs/WORKFLOW.md).

## Repository workflow

CI has read-only repository permissions and does not execute untrusted PR code
through `pull_request_target`. Checkout Actions are pinned to reviewed immutable
commits, with version provenance beside each pin. The Octave base image is
digest-pinned. The actionlint tool uses an explicit reviewed version tag.
Dependencies installed through the distribution package manager are not a fully
reproducible lockfile; review changes and upstream security updates periodically.

`main` requires a PR and successful `repository-policy`, `octave-tests` and
`tex-preview` checks against an up-to-date base. Force pushes and branch deletion
are blocked, including for administrators. No extra independent approval is
required in the current single-maintainer workflow. Private vulnerability
reporting, secret scanning, push protection, Dependabot alerts and automated
security fixes were verified enabled on 2026-09-13. Recheck these live settings
at releases; this dated statement is not a permanent assertion of hosted state.
