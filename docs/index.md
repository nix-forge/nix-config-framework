# nix-config-framework

`nix-config-framework` discovers NixOS, Home Manager, and nix-darwin targets
from a predictable repository layout. It leaves each target's `default.nix` as
the place that selects reusable modules.

Start with the [complete minimal consumer](getting-started.md). Read the
[compatibility and upgrade policy](compatibility.md) before changing the
framework pin in an existing configuration. For a single small home profile,
ordinary module imports may be simpler than adopting a discovery framework.

The [repository README](https://github.com/nix-forge/nix-config-framework#readme)
is the concise interface reference. Source, tests, and release history remain in
the GitHub repository.

## Maintain the documentation

Build the same static artifact that CI publishes:

```console
nix build .#documentation-site
```

Preview edits locally:

```console
nix develop .#docs --command mkdocs serve --config-file site/mkdocs.yml
```
