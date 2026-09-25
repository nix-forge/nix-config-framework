# OpenSSF baseline policy

This repository uses the [OSPS Baseline](https://baseline.openssf.org/versions/2026-08-28)
version 2026.08.28 as its security policy reference. The policy covers the
flake-parts framework, public module contracts, documentation site, CI, and
source releases.

## Current assessed status

The [current self-assessment](https://www.bestpractices.dev/en/projects/14641/baseline-2)
records OSPS Baseline Level 2 for version 2026.08.28. The 13 signed v0.1.x
source tags are releases under the Baseline's definition. Each now has a
[GitHub Release](https://github.com/nix-forge/nix-config-framework/releases)
with a retrospective functional and security change log, a source archive,
checksums, a hash manifest, and Sigstore provenance. The protected
[backfill run](https://github.com/nix-forge/nix-config-framework/actions/runs/36081870928)
verified all four content assets before publication; downloaded archives and
attestations were independently rechecked afterward. OSPS-BR-04.01 and
OSPS-BR-06.01 are **met**. The [Developer Best Practices assessment](https://www.bestpractices.dev/en/projects/14641/passing)
has reached Passing.

Level 3 is not claimed. The protected `main` branch requires zero independent
human approvals, so OSPS-QA-07.01 is **unmet** while the project has one
maintainer. The published assessment records other unmet Level 3 controls.
Future claims require an evidence-backed review of every applicable control.

## Project scope and releases

nix-config-framework is a reusable library for convention-based NixOS, Home
Manager, and nix-darwin configurations. It has source releases in the v0.1.x
tag series. Future releases will use reviewed main commits, immutable tags,
and versioned notes linked from [docs/releases.md](releases.md).
The project publishes source, not compiled binary assets. Its provenance
builder and verification contract are documented in [docs/slsa.md](slsa.md).

This repository is part of the related projects listed in the
[nix-forge project security contract](https://github.com/nix-forge/.github/blob/main/PROJECTS.md).
Related repositories enforce the same minimum security contract or a stricter
one for their own code and release surfaces.

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
| Releases and change logs | [Historical notes](releases/README.md), [published releases](https://github.com/nix-forge/nix-config-framework/releases), signed tags, and attested manifests |
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
