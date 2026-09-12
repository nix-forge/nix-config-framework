# Minimal framework consumer

This complete flake builds a small Home Manager profile with GNU Hello and two
configuration files. It needs Nix with `nix-command` and `flakes` enabled, Git,
and network access to fetch its public locked inputs. It needs no secrets.

## Build and inspect

Choose the target matching your machine:

| Machine | Profile |
| --- | --- |
| Intel or AMD Linux | `alice@x86_64-linux` |
| ARM Linux | `alice@aarch64-linux` |
| Apple Silicon macOS | `alice@aarch64-darwin` |

From this directory, build the default profile for your current system:

```sh
nix build
cat result/home-files/.config/framework-example/settings
cat result/home-files/.config/framework-example/profile
nix flake check
```

The first file contains `editor = vi`; the second contains
`This file belongs to this profile.` Building creates a `result` symlink without
changing your home. The check also verifies the activation script and Hello
executable exist. `nix flake check` builds checks for the current system.

## Trace a setting

The files form this path:

```text
flake.nix
  nixConfigFramework.root = ./.
    homes/<system>/default.nix
      modules = [ modules.tools-basic ]
        modules/home/tools/basic.nix
      local/home.nix
```

`tools/basic.nix` becomes the selector `tools-basic`. Each profile explicitly
selects it. The framework also imports the profile's `local/home.nix`, where
`home.stateVersion` and its own text file belong. Remove `modules.tools-basic`
from a profile to remove that profile's Hello package and settings file.

The directory name and username produce the exported profile name. For example,
`homes/x86_64-linux` and `username = "alice"` produce
`homeConfigurations."alice@x86_64-linux"`.

## Make it yours

Copy this entire directory into a new repository, including `flake.lock`.
Edit each `homes/<system>/default.nix` you keep and set your actual `username`
and absolute `homeDirectory`. In `flake.nix`, update the `homeConfigurations`
lookup to use your username. If you remove unused profiles, also set `systems`
in the `mkFlake` module to the remaining system names, for example
`systems = [ "x86_64-linux" ];`. Checks and packages are generated for that list.
Keep `home.stateVersion` at its initial value when updating inputs; consult
[Home Manager's release notes](https://nix-community.github.io/home-manager/release-notes.xhtml)
before changing state compatibility.

Track every new Nix file before building in a Git checkout:

```sh
git init
git add flake.nix flake.lock homes modules README.md
nix build
```

Inspect `result/home-files` and compare it with files you already manage. Once
the profile contains your correct account details, activate as that user:

```sh
./result/activate
```

Activation changes your home. Home Manager reports existing files that would
collide with managed files; review and move those files yourself. Do not run the
example's Alice profile as your real account or run its activation with `sudo`.
The assertions in `checks.generated-home` describe the original example. Update
them when you intentionally change its behavior.

## Update and verify

`flake.lock` pins every input. To update Nixpkgs and Home Manager together:

```sh
nix flake update nixpkgs home-manager
nix flake check
nix build
```

The framework input uses an immutable published revision. Change its URL when
you choose a newer framework revision, then update its lock entry:

```sh
nix flake update nix-config-framework
```

Read the framework compatibility guide before updating.

See the [framework documentation](https://github.com/nix-forge/nix-config-framework)
for host attachment, shared modules and selector contracts. Ordinary Home Manager
imports are enough for a small profile; use this layout when several targets
reuse independently selected modules.
