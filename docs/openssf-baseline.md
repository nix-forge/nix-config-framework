# OpenSSF baseline policy

This repository follows the [OSPS Baseline](https://baseline.openssf.org/versions/2026-08-28)
version 2026.08.28. The policy covers the flake-parts framework, public module
contracts, documentation site, CI, and source releases.

## Project scope and releases

nix-config-framework is a reusable library for convention-based NixOS, Home
Manager, and nix-darwin configurations. It has source releases in the v0.1.x
tag series. A release is created from reviewed main with an immutable unique
tag and a compatibility entry in [docs/compatibility.md](compatibility.md).
The project publishes source, not compiled binary assets.

## Change and build controls

Every commit must carry a matching Signed-off-by trailer. The DCO file defines
the certificate and .github/workflows/dco.yml checks proposed non-merge commits
on pull requests and merge-group refs.

All workflows start with empty default permissions. Jobs grant only the scopes
they need, checkout does not persist credentials, and actions use full commit
SHAs. Pull requests and merge groups run flake checks, dependency review,
CodeQL, documentation builds, and focused tests before protected main can
advance.

The normal evidence set is:

    nix flake check --show-trace
    nix build .#documentation-site

Changes to discovery, selectors, exported outputs, or compatibility include a
fixture or consumer test and update public documentation. Never commit
consumer credentials, private paths, or generated secrets.

## Release and dependency controls

Flake inputs and compatibility changes are reviewed with their security and
migration impact. Dependency review blocks new low-or-higher severity
vulnerabilities. CodeQL and SCA findings must be fixed before a release unless
a reviewed suppression records why the finding is not exploitable.

Each source release records the reviewed commit, unique tag, compatibility
impact, public interfaces, security changes, release actor and workflow,
verification method, threat-model review, and support window. Consumers verify
the tag and source commit. The project does not upload opaque compiled assets.

The [dependency management policy](dependency-management.md) defines the
approved dependency sources, lockfile review, automated SCA gates, and release
exceptions. The [secret management policy](secret-management.md) defines how
consumer and release credentials are stored, accessed, rotated, and revoked.

## Governance and vulnerability response

The maintainers listed in [GOVERNANCE.md](https://github.com/nix-forge/nix-config-framework/blob/main/GOVERNANCE.md) own repository
administration, Actions secrets, Pages, dependency policy, and releases.
Sensitive access is granted after review of the contributor's history and
intended responsibility. New maintainers receive the narrowest role needed.

Report vulnerabilities through [SECURITY.md](https://github.com/nix-forge/nix-config-framework/blob/main/SECURITY.md) or GitHub private
vulnerability reporting. The maintainer acknowledges reports within three
business days and provides an initial assessment within seven days. Public
disclosure follows a fix or documented mitigation. [security/vex.json](https://github.com/nix-forge/nix-config-framework/blob/main/security/vex.json)
records reviewed non-affectability statements. Support rules are in
[SUPPORT.md](https://github.com/nix-forge/nix-config-framework/blob/main/SUPPORT.md) and compatibility policy.

## Control evidence

| Control area | Evidence |
| --- | --- |
| Least-privilege CI and trusted inputs | Empty default permissions, job scopes, pinned actions, quoted inputs, and no fork secrets |
| Releases and change logs | [docs/compatibility.md](compatibility.md) and source tags |
| Dependencies | flake.lock, dependency review, and CodeQL |
| Build and test instructions | [CONTRIBUTING.md](https://github.com/nix-forge/nix-config-framework/blob/main/CONTRIBUTING.md) |
| Governance | [GOVERNANCE.md](https://github.com/nix-forge/nix-config-framework/blob/main/GOVERNANCE.md) |
| Contributor legal agreement | [DCO](https://github.com/nix-forge/nix-config-framework/blob/main/DCO) and .github/workflows/dco.yml |
| Security assessment | [THREAT_MODEL.md](https://github.com/nix-forge/nix-config-framework/blob/main/THREAT_MODEL.md) |
| Vulnerability response | [SECURITY.md](https://github.com/nix-forge/nix-config-framework/blob/main/SECURITY.md), private reporting, advisories, and [security/vex.json](https://github.com/nix-forge/nix-config-framework/blob/main/security/vex.json) |
| Public interfaces and release identity | Module contracts, compatibility docs, reviewed commits, and source tags |
| Support lifecycle | [SUPPORT.md](https://github.com/nix-forge/nix-config-framework/blob/main/SUPPORT.md) and compatibility policy |

Review this policy when discovery, selector, module, CI, dependency, or
release behavior changes.
