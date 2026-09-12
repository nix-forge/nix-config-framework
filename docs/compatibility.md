# Compatibility and upgrades

The consumer owns its Nixpkgs, Home Manager, nix-darwin and flake-parts pins. Set
the framework's corresponding inputs to `follows` those inputs, as shown in the
[minimal consumer](../examples/minimal/flake.nix). Commit the consumer lock file.
`follows` shares a pin; it does not make incompatible upstream versions compatible.

## What is checked

| Contract | Coverage |
| --- | --- |
| Discovery, selectors and target assertions | Framework discovery and integration checks |
| Embedded Darwin homes and shell registration | Darwin fixture evaluation, including assertions |
| Standalone public example | Generated home files and activation package on the CI native matrix |
| Systems in the default matrix | `x86_64-linux`, `aarch64-linux`, `aarch64-darwin` |
| Other systems or stable Nixpkgs releases | No compatibility promise; test your consumer pins |
| Activation on a real workstation | The consumer's responsibility; CI builds do not activate personal homes |

CI runs the public example with its lock file and also overrides the framework
input with the revision under test. This separates a reproducible published
consumer from testing whether framework changes preserve that consumer.
Inspect the [CI workflow](../.github/workflows/ci.yml) and its actual run results
before treating a revision as validated. Configured coverage is not a statement
that every historical revision passed.

Intel macOS is outside the default matrix. Nixpkgs unstable no longer supports
it. Supporting it requires a compatible Nixpkgs release and an explicit
flake-parts `systems` value, followed by your own evaluation and native checks.

## Update a consumer

Keep Nixpkgs and Home Manager on compatible release tracks. Update those inputs
together, inspect upstream release notes, and build before activation. Review
nix-darwin updates on a Darwin machine when you have Darwin hosts. Keep existing
`home.stateVersion` and `system.stateVersion` values unless the upstream migration
instructions call for a deliberate change.

The minimal example uses the published framework revision
`11e4d9dfe816b9855ae9de8318734059d616d3a1`. Its exact upstream pins live in
[its lock file](../examples/minimal/flake.lock); they are the reproducible baseline
for the guide, not a claim of support for arbitrary future upstream revisions.

When upgrading the framework:

- Step 1: read the [release history][release-history] and compare the
  old and new revisions. If a commit has no release notes, inspect its
  diff; do not assume a migration guide exists.
- Step 2: change the framework input URL and update that input's lock
  entry.
- Step 3: evaluate every consumer target, build each native check, and
  inspect generated files. A successful evaluation alone does not prove
  a native build works.
- Step 4: commit the working lock file so a rollback can restore the
  previous pins.

[release-history]: https://github.com/nix-forge/nix-config-framework/releases

## Release notes for maintainers

The onboarding work is unreleased until a maintainer publishes it. A release
should describe changes to selectors, exported outputs, target specifications
and special arguments, with before-and-after consumer examples for migrations.
Record the tested input revisions, native build results and known limits.
Run the minimal consumer against the release candidate before tagging it.

These are release requirements for future changes, not retroactive guarantees
about existing tags. The README's `v0.1.0` input example remains a versioned API
entry point; the complete consumer's newer commit demonstrates current behavior.
