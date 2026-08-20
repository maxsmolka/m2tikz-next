# Security policy

## Reporting a vulnerability

Do not report suspected vulnerabilities, credentials, or sensitive data in a
public issue.

Use GitHub Private Vulnerability Reporting from the repository's **Security**
page when that option is available. If the private reporting form is not
available, contact the repository owner through their GitHub profile before
sharing details; do not substitute a public issue or discussion.

## Supported versions

| Version | Security updates |
| --- | --- |
| 0.5.x | Planned current public preview line |
| Earlier m2tikz-next development versions | Not supported |
| Original matlab2tikz releases | Refer to the upstream project |

The 0.5.0 target is pre-1.0. Security fixes will be evaluated for the current
public minor line; this policy does not promise indefinite maintenance of old
preview versions.

## Release checks

- Verify the private reporting path from the repository Security page.
- Run current-tree confidentiality, secret, and publication-path scans.
- Review security-sensitive dependency and CI changes.
- Keep generated local validation output and credentials out of release
  artifacts.

The inherited Git history is retained for provenance. The historical upstream
CI review is summarized without credential material in
`docs/release/SECURITY_REVIEW.md`.
