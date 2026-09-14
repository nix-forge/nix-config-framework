# Secret management policy

This policy covers maintainer credentials, GitHub Actions tokens, release
approvals, and credentials supplied by framework consumers.

## Storage

- Secrets and private configuration never enter Git, the Nix store, generated
  documentation, release archives, or CI logs.
- GitHub Actions uses repository or environment secrets only when OIDC or
  another short-lived mechanism cannot replace them. Release publication is
  protected by the `release` environment.
- Consumer credentials are supplied by the consumer's secret backend at
  deployment time. The framework does not request or persist them.

## Access and use

- Access is least-privilege and limited to the maintainer role that needs it.
  Organization-wide two-factor authentication and protected `main` apply to
  repository administration.
- Pull requests from forks and other untrusted workflow contexts receive no
  repository secrets. Workflows default to empty permissions and grant only
  the scopes documented beside each job.
- Workflows must not print secrets, interpolate them into source archives, or
  pass them through untrusted shell or pull-request metadata.

## Rotation and response

Maintainers record an owner and purpose for each credential, rotate it at
least annually and whenever a maintainer, provider, or trust boundary changes,
and remove credentials that no longer have a documented owner. Suspected
exposure triggers immediate revocation, replacement, and review of logs and
release artifacts. Report suspected exposure through [SECURITY.md](https://github.com/nix-forge/nix-config-framework/blob/main/SECURITY.md),
not a public issue.

Changes to release credentials or workflow permissions require a pull request,
security-impact notes, and an independent review when another maintainer is
available.
