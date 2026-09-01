{ modules, ... }: {
  system = "aarch64-darwin";
  username = "alice";
  homeDirectory = "/Users/alice";
  uid = 501;
  standalone = false;
  modules = [ modules.target-kind ];
}
