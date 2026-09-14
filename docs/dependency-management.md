# Dependency management policy

This policy covers the framework's Nix inputs, the minimal consumer fixture,
documentation tooling, and GitHub Actions references.

## Inventory and selection

- Every tracked flake has a committed `flake.lock`; nested consumer fixtures
  are reviewed as independent dependency surfaces.
- Inputs are selected for maintained upstream support, a compatible license,
  and a clear source. Lock entries use immutable revisions and hashes.
- A dependency update records its compatibility impact, security impact, and
  any required migration in the pull request. Updates that change the public
  framework contract include a consumer fixture or contract test.
- Actions and reusable workflows use full commit-SHA references. Dependabot
  keeps those references and the lockfiles current.

## Automated evaluation

Pull requests run flake-lock validation, dependency review, CodeQL, repository
hooks, and the native test matrix. Dependency review is configured to fail on
low-or-higher severity findings when GitHub can analyze the repository's
manifests. CodeQL findings and Nix evaluation failures block the merge queue.

## Remediation and release gate

Malicious dependencies, known exploited vulnerabilities, high or critical SCA
findings, and prohibited licenses block release. Low and medium findings are
also resolved before release unless a maintainer records a time-bounded,
non-exploitable exception in `security/vex.json` and links the analysis in the
release notes. Exceptions name an owner, affected versions, compensating
controls, and an expiry or review date.

Before tagging a release, review every changed lock entry, run the documented
flake and consumer checks, and confirm that no unresolved SCA or license
violation is included in the source archive.

## Maintenance

Maintainers review dependency updates through pull requests. A stale or
unmaintained dependency is replaced when a supported alternative exists; an
unavoidable exception is documented with its operational and security risk.
