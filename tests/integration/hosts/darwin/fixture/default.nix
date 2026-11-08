{ inputs, ... }: {
  system = "aarch64-darwin";
  hostName = "fixture";
  modules = [
    { system.stateVersion = 6; }
    ./target-name.nix
  ];

  homeManagerExtraSpecialArgs = {
    configName = "wrong-host-name";
    targetName = "wrong-host-target";
  };

  homes.alice = {
    config = "alice@workstation-home";
    user.shell = inputs.nixpkgs.legacyPackages.aarch64-darwin.nushell;
  };
}
