# nix-config-framework

`nix-config-framework` is a small flake-parts framework for convention-based
NixOS, Home Manager, and nix-darwin configurations. It discovers reusable
features from paths and leaves each target's `default.nix` as the single place
that selects features.

## Use it

Add the framework to a flake and make its core inputs follow your pins:

```nix
inputs.nix-config-framework.url = "github:IanHollow/nix-config-framework/v0.1.0";
inputs.nix-config-framework.inputs.nixpkgs.follows = "nixpkgs";
inputs.nix-config-framework.inputs.flake-parts.follows = "flake-parts";
inputs.nix-config-framework.inputs.home-manager.follows = "home-manager";
inputs.nix-config-framework.inputs.nix-darwin.follows = "nix-darwin";

# inside flake-parts mkFlake
imports = [ inputs.nix-config-framework.flakeModules.default ];
nixConfigFramework.root = ./.;
# Optional project-specific helpers for discovered modules:
# nixConfigFramework.extraSpecialArgs.myLib = myLib;
```

When using a git submodule, add `self.submodules = true;` to the root flake so
the module source is available to Nix.

## Layout and selectors

```text
modules/{nixos,home,darwin,shared}/
hosts/{nixos,darwin}/<host>/{default.nix,local/}
homes/<profile>/{default.nix,local/}
```

`modules/nixos/hardware/sound/pipewire.nix` is selectable as
`hardware-sound-pipewire`. Selecting `hardware-sound` imports every Nix file
below that directory when it has no `default.nix`. A directory with a
`default.nix` is a deliberate feature boundary: selecting it imports that
default module, while its children remain independently selectable variants.

`modules/shared/foo.nix` returns an envelope with any combination of `nixos`,
`homeManager`, and `darwin` modules. Only the matching class is exported.

Every file beneath a target's `local/` directory is imported automatically after
its selected generic features. Keep helpers and inactive experiments outside
`local/` (for example under `archive/`).

## Target specifications

```nix
# homes/work/default.nix
{ modules, ... }: {
  system = "x86_64-linux";
  username = "alice";
  homeDirectory = "/home/alice";
  modules = with modules; [ shells-zsh dev-git ];
}

# hosts/nixos/laptop/default.nix
{ modules, ... }: {
  system = "x86_64-linux";
  hostName = "laptop";
  modules = with modules; [ base ];
  homes.alice = {
    config = "alice@work";
    user = { isNormalUser = true; extraGroups = [ "wheel" ]; };
  };
}
```

For a nix-darwin host, set a login shell in the attached user's `user` attribute
set. The framework registers every such shell in `environment.shells`, which
causes nix-darwin to manage `/etc/shells` with the same login-shell path.

```nix
homes.alice = {
  config = "alice@work";
  user.shell = pkgs.nushell;
};
```

The flake exports typed `flake.modules.{nixos,homeManager,darwin}` and the
compatibility aliases `nixosModules`, `homeModules`, and `darwinModules`, as
well as `nixosConfigurations`, `darwinConfigurations`, and `homeConfigurations`.
`config.nixConfigFramework.inventory` is available to other flake-parts modules
in the same flake for extensions such as secret indexing.

The default system set is `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`.
Intel macOS consumers should pin a nixpkgs release that still supports
`x86_64-darwin` and override the flake-parts `systems` option explicitly.
