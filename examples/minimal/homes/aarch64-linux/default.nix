{ modules, ... }: {
  system = "aarch64-linux";
  username = "alice";
  homeDirectory = "/home/alice";
  modules = [ modules.tools-basic ];
}
