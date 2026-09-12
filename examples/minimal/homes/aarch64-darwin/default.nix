{ modules, ... }: {
  system = "aarch64-darwin";
  username = "alice";
  homeDirectory = "/Users/alice";
  modules = [ modules.tools-basic ];
}
