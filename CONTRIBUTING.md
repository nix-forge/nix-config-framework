# Contributing

This repository provides a reusable flake-parts framework for NixOS, nix-darwin,
and Home Manager consumers. Contributions should remain useful outside the
maintainer's configurations and should not depend on private files or paths.

Before a larger change, open an issue describing the framework contract, the
consumer impact, and the compatibility or migration plan. Keep pull requests
focused. Update the README and reference documentation when a discovery rule,
option, or exported output changes.

Run `nix flake check` and the focused tests for the area you changed. Include a
minimal consumer or fixture when changing target discovery, module selection, or
compatibility behavior.

Do not commit secrets, generated credentials, or large binary artifacts. Use
full immutable references for GitHub Actions and preserve the repository's
least-privilege workflow permissions.

Commits should include a sign-off with `git commit -s`. This records agreement
to the [Developer Certificate of Origin](https://developercertificate.org/).

Submit changes as pull requests against `main`. The protected branch requires
review, passing checks, and the merge queue before changes are accepted.
