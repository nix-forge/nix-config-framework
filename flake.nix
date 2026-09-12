{
  description = "Convention-based NixOS, Home Manager, and nix-darwin configuration assembly";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0";
    home-manager.url = "github:nix-community/home-manager";
    nix-darwin.url = "github:nix-darwin/nix-darwin";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      exportSchema = what: valid: {
        version = 1;
        doc = "Validate the shape of exported ${what}; behavioral checks are in checks.";
        inventory = output: {
          evalChecks.isAttributeSet = builtins.isAttrs output;
          children = builtins.mapAttrs (_: value: {
            inherit what;
            evalChecks.isValidExport = valid value;
          }) output;
        };
      };
      moduleSchema = exportSchema "Nix module" (
        value: builtins.isFunction value || builtins.isAttrs value
      );
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
      standaloneHomes = integrationFixture.homeConfigurations;
      failedAssertions = builtins.filter (
        entry: !entry.assertion
      ) integrationFixture.darwinConfigurations.fixture.config.assertions;
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
          assert nixpkgs.lib.assertMsg (failedAssertions == [ ]) (
            "Integration fixture assertions failed: "
            + nixpkgs.lib.concatMapStringsSep "; " (entry: entry.message) failedAssertions
          );
          assert embeddedHomeTargetKind == "home";
          assert nixpkgs.lib.elem fixtureNushellPath registeredDarwinShells;
          assert !(standaloneHomes ? "alice@fixture");
          assert standaloneHomes ? "bob@standalone";
          pkgs.runCommand "discovery" { } "touch $out";
      };

      flake = {
        schemas = inputs.flake-schemas.exportedSchemas // {
          flakeModules = moduleSchema;
          lib = exportSchema "library function" builtins.isFunction;
        };
        lib = import ./lib { inherit (nixpkgs) lib; };
        flakeModules.default = import ./flake-module.nix;
      };
    };
}
