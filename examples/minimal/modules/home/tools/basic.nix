{ pkgs, ... }: {
  home.packages = [ pkgs.hello ];
  xdg.configFile."framework-example/settings".text = ''
    editor = vi
  '';
}
