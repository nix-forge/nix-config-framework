# Release notes

Create one file named `vX.Y.Z.md` for every source release. Start it with a
`## Changelog` section and describe functional changes, security impact,
affected consumers, compatibility or migration requirements, the checks that
ran, and the support and end-of-life window. Name the reviewed source commit
and release workflow when documenting verification.

The normal release workflow requires the tag-specific file in the tagged
source archive and calls the pinned `nix-forge/ci` reusable builder. That
builder creates GitHub build provenance before the protected publisher
verifies and releases its assets. Keep future notes descriptive and review
them together with the code before creating the tag.

The notes for v0.1.0 through v0.1.12 are retrospective. They describe the
changes in the original signed tags, but are not part of those tagged source
trees. The separate historical backfill workflow publishes these notes with
the attested release assets. Its provenance identifies the later backfill
process, not an original build from July 2026.
