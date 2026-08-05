{
  description = "Convention-based NixOS, Home Manager, and nix-darwin configuration assembly";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager";
    nix-darwin.url = "github:nix-darwin/nix-darwin";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      testPasses = import ./tests { inherit (nixpkgs) lib; };
      integrationFixture = inputs.flake-parts.lib.mkFlake { inherit inputs; } {
        systems = [ "aarch64-darwin" ];
        imports = [ ./flake-module.nix ];
        nixConfigFramework = {
          root = ./tests/integration;
          extraSpecialArgsFor = { kind, ... }: { targetKind = kind; };
        };
      };
      embeddedHomeTargetKind =
        integrationFixture.darwinConfigurations.fixture.config.home-manager.users.alice.home.sessionVariables.FRAMEWORK_TARGET_KIND;
      fixtureNushell = inputs.nixpkgs.legacyPackages.aarch64-darwin.nushell;
      fixtureNushellPath = "/run/current-system/sw/bin/${fixtureNushell.meta.mainProgram}";
      registeredDarwinShells = map toString integrationFixture.darwinConfigurations.fixture.config.environment.shells;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./flake/partitions.nix ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, ... }: {
        checks.discovery =
          assert testPasses;
          assert embeddedHomeTargetKind == "home";
          assert nixpkgs.lib.elem fixtureNushellPath registeredDarwinShells;
          pkgs.runCommand "discovery" { } "touch $out";
      };

      flake = {
        lib = import ./lib { inherit (nixpkgs) lib; };
        flakeModules.default = import ./flake-module.nix;
      };
    };
}
