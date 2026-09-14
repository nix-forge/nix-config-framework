# Release process

The framework uses immutable semantic-version source tags in the v0.1.x series.
A release starts from a reviewed commit on main after the pull request has
passed flake checks, dependency review, CodeQL, the DCO check, documentation
builds, and focused consumer tests.

## Candidate checklist

1. Update the release notes with selector, exported-output, compatibility, and
  migration changes.
2. Run nix flake check and build the documentation site.
3. Run the minimal public consumer against the candidate commit and record the
  tested Nixpkgs, Home Manager, nix-darwin, and flake-parts revisions.
4. Inspect generated documentation and a clean checkout for private paths,
  credentials, and generated secrets.
5. Tag the exact reviewed commit. Do not tag a dirty working tree.
6. Verify the tag and source commit before announcing the release.

The project publishes source, not opaque compiled assets. Release notes name
the actor and process, list public module interfaces, explain security impact,
describe source verification, link the threat model, and state the support and
end-of-life window. A release stops receiving security updates when its support
window ends or a later major contract removes it from the supported matrix.

## Compatibility

Discovery paths, selectors, target specifications, exported outputs, and
special arguments are public APIs. Breaking changes require a migration note,
updated fixtures, a working minimal consumer, and a release entry before the
tag is created.
