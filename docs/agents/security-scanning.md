# Security scanning

> Moved verbatim from `CLAUDE.md` on 2026-11-11 (security scanning). `CLAUDE.md` points here; keep this file accurate whenever the behaviour it describes changes.

## Security scanning

Configured in the GitHub repository settings, not in files:

- **CodeQL** default setup on the Actions workflows (the only language CodeQL finds here): on every
  push, on pull requests and weekly. Findings: Security → Code scanning.
- **Secret scanning with push protection**: a push containing a recognised secret is rejected. It
  is the only check that blocks anything. If it fires on a real secret, remove it from the commit and
  rotate the secret; never bypass it.
- **Dependabot alerts and security updates**, but no `dependabot.yml`, so no routine version-bump
  pull requests.
- Findings never block a release: GitHub notifies the owner. When one needs work, open a GitHub
  issue (see `CLAUDE.md`, "Agent skills").
