# Start with a standalone home

The [minimal consumer](../examples/minimal/README.md) is a complete flake with a
lock file, three neutral home targets and a check of the generated files. Start
there to understand selectors without configuring a host or supplying secrets.

Clone the framework and copy the example into an empty directory of your own:

```sh
git clone https://github.com/nix-forge/nix-config-framework.git
cp -R nix-config-framework/examples/minimal ./my-nix-home
cd my-nix-home
nix build
cat result/home-files/.config/framework-example/settings
nix flake check
```

The displayed setting should be `editor = vi`. Follow the example's README to
set your username and home directory before activation. The example pins its
framework input to a published revision, so it works outside this repository.
The three target directories keep system selection explicit and allow evaluation
from another platform. Native builds still require a matching machine or builder.

## Decide whether you need the framework

If you have one `home.nix`, an ordinary `imports` list is a good starting point.
Nix already combines modules. The framework adds directory discovery, named
feature selection and host-to-home connections when those remove repetition
across your targets. It does not replace Home Manager or NixOS module options.

The layout is intentionally small:

| Responsibility | Example |
| --- | --- |
| Consumer pins and framework import | `flake.nix` |
| Reusable Home Manager feature | `modules/home/tools/basic.nix` |
| Target identity and feature selection | `homes/x86_64-linux/default.nix` |
| Settings belonging to one target | `homes/x86_64-linux/local/home.nix` |

Keep helpers outside `local/`, where every Nix file is imported as a module.
The [selector reference](../README.md#layout-and-selectors) explains directory
boundaries and shared modules. The [target reference](../README.md#target-specifications)
explains attaching a home to a NixOS or nix-darwin host.

## Add a reusable feature

Create `modules/home/editor.nix` in your copy:

```nix
{
  programs.helix.enable = true;
}
```

Add `modules.editor` to the selected target's `modules` list, stage the new file,
and build again. Home Manager owns the `programs.helix` option and its generated
configuration; the framework owns how the target selects that module.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| A new selector is missing | Stage the Nix file, check its path and the generated hyphenated name. |
| A helper causes module errors | Move it out of `local/`; import it from the module that uses it. |
| Home Manager reports the wrong account | Update the target's username and home directory before activation. |
| A host-only profile fails standalone | Set `standalone = false` and use the host that provides its dependencies. |
| An input update fails | Restore the previous lock file, then follow the compatibility guide. |

Upstream references: [Home Manager configuration](https://github.com/nix-community/home-manager/blob/master/docs/manual/usage/configuration.md)
and [flake-parts module composition](https://flake.parts/define-module-in-separate-file.html).
