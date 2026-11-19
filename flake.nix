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
        doc = "Validate the shape of exported ${what}.";
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
              '';
        in
        {
          packages.documentation-site = documentationSite;
          checks = {
            lib-tests = pkgs.runCommand "framework-lib-tests" { nativeBuildInputs = [ pkgs.nix-unit ]; } ''
              export HOME="$TMPDIR"
              nix-unit --eval-store "$TMPDIR/eval-store" --expr 'import ${./lib}/tests { lib = import ${nixpkgs}/lib; }'
              touch "$out"
            '';
          }
          // nixpkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
            documentation-site = documentationSite;
          };
          devShells.docs = pkgs.mkShellNoCC { packages = [ mkdocs ]; };
        };

      flake = {
        libTests = import ./lib/tests { inherit (nixpkgs) lib; };
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
