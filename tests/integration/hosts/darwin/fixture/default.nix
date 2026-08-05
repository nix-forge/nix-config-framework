{ inputs, ... }: {
  system = "aarch64-darwin";
  hostName = "fixture";
  modules = [
    { system.stateVersion = 6; }
    ./target-name.nix
  ];

  homes.alice = {
    config = "alice@fixture";
    user.shell = inputs.nixpkgs.legacyPackages.aarch64-darwin.nushell;
  };
}
