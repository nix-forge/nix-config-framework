# Compatibility and upgrades

The consumer owns its Nixpkgs, Home Manager, nix-darwin and flake-parts pins. Set
the framework's corresponding inputs to `follows` those inputs, as shown in the
[minimal consumer](https://github.com/nix-forge/nix-config-framework/blob/main/examples/minimal/flake.nix). Commit the consumer lock file.
`follows` shares a pin; it does not make incompatible upstream versions compatible.

## What is checked

The declared native matrix is `x86_64-linux`, `aarch64-linux` and
`aarch64-darwin`. CI runs Nix library unit tests, static tooling, documentation
builds and export-schema validation. Library cases cover discovery, selectors
and composition. Assertions in modules reject invalid configuration settings.

There are no automated consumer or module integration fixtures. The public
example remains a usable consumer, but building and activating consumer targets
is the consumer's responsibility. Other systems or stable Nixpkgs releases have
no compatibility promise. Inspect the
[CI workflow](https://github.com/nix-forge/nix-config-framework/blob/main/.github/workflows/ci.yml)
and actual results before treating a revision as checked.

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
[its lock file](https://github.com/nix-forge/nix-config-framework/blob/main/examples/minimal/flake.lock); they are the reproducible baseline
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
Record any manual consumer build evidence separately from the library test results.

These are release requirements for future changes, not retroactive guarantees
about existing tags. The README's `v0.1.0` input example remains a versioned API
entry point; the complete consumer's newer commit demonstrates current behavior.
