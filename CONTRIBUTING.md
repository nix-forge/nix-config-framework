# Contributing

This repository provides a reusable flake-parts framework for NixOS, nix-darwin,
and Home Manager consumers. Contributions should remain useful outside the
maintainer's configurations and should not depend on private files or paths.

Before a larger change, open an issue describing the framework contract, the
consumer impact, and the compatibility or migration plan. Keep pull requests
focused. Update the README and reference documentation when a discovery rule,
option, or exported output changes.

## Testing policy

Automated behavior tests cover functions in `lib/` only, using nix-unit's named
`expr`/`expected` and `expectedError` cases under `lib/tests/`. Run
`nix build .#checks.x86_64-linux.lib-tests` (replace the system for another
native platform). The development shell provides `nix-unit --flake '.#libTests'`
for a focused run.

Other checks are static formatting, lint, syntax, type, export-schema,
documentation, dependency and security analysis. CI runs those checks and the
library suite on the declared native matrix. `nix flake check` builds the
complete declared check set; build the documentation site before review.

Keep assertions validating settings in their owning modules. Do not add
configuration snapshots, module integration, release-workflow regression or fuzz
tests. Preserve production input validation and ordinary consumer build outputs.
Library tests do not establish successful activation or consumer compatibility;
record native operational evidence separately when needed. Security and
dependency findings follow the
[dependency-management policy](docs/dependency-management.md).

Do not commit secrets, generated credentials, or large binary artifacts. Use
full immutable references for GitHub Actions and preserve the repository's
least-privilege workflow permissions.

Commits should include a sign-off with `git commit -s`. This records agreement
to the [Developer Certificate of Origin](https://developercertificate.org/).

Submit changes as pull requests against `main`. The maintainer decides whether
the review is sufficient; passing checks and the merge queue are required.
