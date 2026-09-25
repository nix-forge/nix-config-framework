# Release process

The framework uses immutable semantic-version source tags in the v0.1.x series.
Future GitHub source releases must start from a reviewed commit on main after
the pull request has passed flake checks, dependency review, CodeQL, the DCO
check, documentation builds, and focused consumer tests.

## Historical source tags

The public v0.1.x tags through v0.1.12 identify versioned source trees. They
were published without per-tag release notes or a signed manifest for the
GitHub-generated archives. Reviewed retrospective notes now live in
[`docs/releases/`](releases/README.md). The manually dispatched
`backfill-source-releases.yml` workflow checks each signed tag against the
protected main branch, builds its source archive, attests the archive, checksum,
notes, and manifest, then publishes a GitHub Release through the protected
`release` environment. The release page states that the notes were added later.
The current [OpenSSF assessment](openssf-baseline.md) records the verified
status; a workflow definition or draft note alone is not release evidence.

## Candidate checklist

1. Create `docs/releases/v0.1.x.md` for the exact tag. It must contain a
   `## Changelog` section with functional and security changes, affected
   consumers, migration notes, and the checks and support window for the
   release. The release workflow rejects a tag without this file.
2. Run nix flake check and build the documentation site.
3. Run the minimal public consumer against the candidate commit and record the
   tested Nixpkgs, Home Manager, nix-darwin, and flake-parts revisions.
4. Inspect generated documentation and a clean checkout for private paths,
   credentials, and generated secrets.
5. Tag the exact reviewed commit. Do not tag a dirty working tree.
6. Verify the release using the commands below.

## Verification

For example:

```console
gh release download v0.1.x --repo nix-forge/nix-config-framework --dir release-v0.1.x
(cd release-v0.1.x && sha256sum -c nix-config-framework-v0.1.x.tar.gz.sha256)
gh attestation verify release-v0.1.x/nix-config-framework-v0.1.x.tar.gz \
  --repo nix-forge/nix-config-framework \
  --signer-workflow nix-forge/ci/.github/workflows/slsa-source-release.yml \
  --signer-digest bb1b39a9082f72dc6c7ce596103ce7a5e4d29b01
```

For a historical backfilled release, use its `nix-config-framework-v0.1.x.intoto.jsonl`
bundle and verify **each** uploaded content asset (`.tar.gz`, `.tar.gz.sha256`,
`release-notes.md`, and `release-manifest.txt`) with `gh attestation verify`
and `--signer-workflow nix-forge/nix-config-framework/.github/workflows/backfill-source-releases.yml`.
Check that the manifest's `signed_tag_object` is the GitHub-verified signed tag
and that `source_commit` matches its peeled commit. The backfill's signer is
the framework workflow on protected main, not the future reusable builder.
These retrospective attestations make no claim that the original 2026-07-21
and 2026-07-22 builds had provenance.

The expected release identity is the `nix-forge/nix-config-framework`
repository and the pinned `nix-forge/ci/.github/workflows/slsa-source-release.yml`
reusable builder. Keep the digest in this command synchronized with
`.github/workflows/release.yml`.

The project publishes source, not opaque compiled assets. The reusable builder
creates and attests the archive, checksum, and manifest; the protected
publisher verifies their bytes and signer, attaches them to a draft, and then
publishes the immutable release. Release notes name the actor and process, list
public module interfaces, explain security impact, describe source
verification, link the threat model, and state the support and end-of-life
window. A release stops receiving security updates when its support window ends
or a later major contract removes it from the supported matrix.

## Compatibility

Discovery paths, selectors, target specifications, exported outputs, and
special arguments are public APIs. Breaking changes require a migration note,
updated fixtures, a working minimal consumer, and a release entry before the
tag is created.
