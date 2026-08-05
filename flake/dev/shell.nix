{
  perSystem =
    { config, pkgs, ... }:
    let
      inherit (config.pre-commit.settings) enabledPackages package shellHook;
    in
    {
      devShells.default = pkgs.mkShellNoCC {
        inherit shellHook;
        packages =
          enabledPackages
          ++ [ package ]
          ++ (with pkgs; [
            actionlint
            deadnix
            direnv
            editorconfig-checker
            flake-checker
            gitleaks
            keep-sorted
            just
            nixd
            nixf-diagnose
            nixfmt
            pinact
            prettier
            prek
            rumdl
            statix
            taplo
            treefmt
            typos
            yamlfmt
            yamllint
            zizmor
          ]);
      };
    };
}
