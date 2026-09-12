{
  description = "A standalone Home Manager consumer of nix-config-framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-config-framework = {
      url = "github:nix-forge/nix-config-framework/11e4d9dfe816b9855ae9de8318734059d616d3a1";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
        nix-darwin.follows = "nix-darwin";
      };
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.nix-config-framework.flakeModules.default ];
      nixConfigFramework.root = ./.;

      perSystem =
        { pkgs, system, ... }:
        let
          home = inputs.self.homeConfigurations."alice@${system}";
        in
        {
          packages.default = home.activationPackage;
          checks.generated-home = pkgs.runCommand "framework-example-home" { } ''
            test -x ${home.activationPackage}/activate
            test -x ${home.config.home.path}/bin/hello
            grep -Fx 'editor = vi' ${home.activationPackage}/home-files/.config/framework-example/settings
            grep -Fx 'This file belongs to this profile.' ${home.activationPackage}/home-files/.config/framework-example/profile
            touch "$out"
          '';
        };
    };
}
