# Release notes

Create one file named `vX.Y.Z.md` for every source release. Start it with a
`## Changelog` section and describe functional changes, security impact,
affected consumers, compatibility or migration requirements, the checks that
ran, and the support and end-of-life window. Name the reviewed source commit
and release workflow when documenting verification.

The release workflow requires the tag-specific file, publishes it inside the
source archive, publishes the checksum and manifest assets, and calls the
pinned `nix-forge/ci` reusable builder. The builder creates GitHub build
provenance before the protected publisher verifies and releases those exact
assets. Keep release notes descriptive and review them together with the code
before creating the tag.
