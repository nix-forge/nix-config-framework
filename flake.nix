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
      mkIntegrationFixture =
        extraInputs:
        inputs.flake-parts.lib.mkFlake { inputs = inputs // extraInputs; } {
          systems = [ "aarch64-darwin" ];
          imports = [ ./flake-module.nix ];
          nixConfigFramework = {
            root = ./tests/integration;
            extraSpecialArgs = {
              configName = "wrong-global-name";
              targetName = "wrong-global-target";
            };
            extraSpecialArgsFor = { kind, ... }: { targetKind = kind; };
          };
        };
      integrationFixture = mkIntegrationFixture { };
      incompatibleHomeFixture = mkIntegrationFixture { fixtureHomeSystem = "x86_64-linux"; };
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
      imports = [
        ./flake/build-platform.nix
        ./flake/partitions.nix
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        let
          mkdocs = pkgs.python3.withPackages (python: [ python.mkdocs ]);
          documentationSite =
            pkgs.runCommand "nix-config-framework-documentation-site" { nativeBuildInputs = [ mkdocs ]; }
              ''
                cp -R ${./docs} docs
                cp -R ${./site} site
                chmod -R u+w docs
                mkdocs build --config-file site/mkdocs.yml --site-dir "$out" --strict
                test -s "$out/index.html"
                test -s "$out/search/search_index.json"
              '';
        in
        {
          packages.documentation-site = documentationSite;
          checks = {
            discovery =
              assert testPasses;
              assert nixpkgs.lib.assertMsg (failedAssertions == [ ]) (
                "Integration fixture assertions failed: "
                + nixpkgs.lib.concatMapStringsSep "; " (entry: entry.message) failedAssertions
              );
              assert nixpkgs.lib.any (
                entry: !entry.assertion && nixpkgs.lib.hasInfix "Attached home" entry.message
              ) incompatibleHomeFixture.darwinConfigurations.fixture.config.home-manager.users.alice.assertions;
              assert embeddedHomeTargetKind == "home";
              assert
                integrationFixture.darwinConfigurations.fixture.config.home-manager.users.alice.home.sessionVariables.FRAMEWORK_CONFIG_NAME
                == "alice@workstation-home";
              assert
                integrationFixture.darwinConfigurations.fixture.config.home-manager.users.alice.home.sessionVariables.FRAMEWORK_TARGET_NAME
                == "workstation-home";
              assert
                integrationFixture.darwinConfigurations.fixture.config.home-manager.users.alice.home.sessionVariables.FRAMEWORK_SYSTEM
                == "aarch64-darwin";
              assert nixpkgs.lib.elem fixtureNushellPath registeredDarwinShells;
              assert !(standaloneHomes ? "alice@workstation-home");
              assert standaloneHomes ? "bob@standalone";
              pkgs.runCommand "discovery" { } "touch $out";
          }
          // nixpkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
            documentation-site = documentationSite;
          };
          devShells.docs = pkgs.mkShellNoCC { packages = [ mkdocs ]; };
        };

      flake = {
        schemas = inputs.flake-schemas.exportedSchemas // {
          flakeModules = moduleSchema;
          lib = exportSchema "library function" builtins.isFunction;
        };
        lib = (import ./lib { inherit (nixpkgs) lib; }) // {
          # These exports are documentation, with no target executables.
          packagesFor = platform: inputs.self.packages.${platform.buildSystem};
        };
        flakeModules.default = import ./flake-module.nix;
      };
    };
}
