# SLSA build provenance

The source archive is a supported release artifact. The release workflow pins
the organization-owned `nix-forge/ci` reusable builder to a reviewed commit.
That builder checks out the immutable tag, creates the archive, checksum, and
manifest, and creates GitHub SLSA build provenance before handing the exact
bytes to the protected publisher job.

The publisher verifies the tag, checksum, source commit, signer workflow, and
builder commit before creating the GitHub Release. The builder has no release
write permission, no long-lived signing key, and no shared release cache.

Verify a downloaded archive with:

```console
gh attestation verify nix-config-framework-vX.Y.Z.tar.gz \
  --repo nix-forge/nix-config-framework \
  --signer-workflow nix-forge/ci/.github/workflows/slsa-source-release.yml \
  --signer-digest bb1b39a9082f72dc6c7ce596103ce7a5e4d29b01
```

These are release controls, not a verified Level 3 claim yet. No published
release asset was available to verify on 21 September 2026. After the first
release, verify its downloaded archive and attestation against the expected
builder before making a Build track claim for those exact bytes. A local flake
evaluation or arbitrary consumer build has separate provenance. See the
[SLSA Build specification](https://slsa.dev/spec/v1.2/)
and [GitHub's Level 3 guidance](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/increase-security-rating)
for the model and verification requirements.
