# Security policy

## Reporting a vulnerability

Do not report suspected vulnerabilities, live credentials, or sensitive data in
a public issue.

The intended private reporting channel is **GitHub Private Vulnerability
Reporting**. This repository is not public yet, so that channel does not yet
exist. The repository owner must enable it when the public GitHub repository is
created and before any public announcement.

Until that channel is enabled, publication remains gated and this repository
does not claim to offer an active private intake address.

## Supported versions

No public m2tikz-next version has been released. A supported-version table will
be added with the first release and updated as preview versions are superseded.

## Release checklist

- Enable GitHub Private Vulnerability Reporting before public announcement.
- Verify the private reporting workflow from the repository Security page.
- Repeat the current-tree secret and publication-path scans.
- Review security-sensitive dependency and CI changes.

The inherited Git history is retained for provenance. The disposition of the
historical upstream CI finding is documented in
`docs/release/SECURITY_REVIEW.md` without reproducing credential material.
