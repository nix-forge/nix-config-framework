{ modules, ... }: {
  system = "x86_64-linux";
  username = "alice";
  homeDirectory = "/home/alice";
  modules = [ modules.tools-basic ];
}
