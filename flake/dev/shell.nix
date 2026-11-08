{
  perSystem =
    { config, pkgs, ... }:
    let
      inherit (config.pre-commit.settings) enabledPackages package shellHook;
    in
    {
      devShells.default = pkgs.buildPackages.mkShellNoCC {
        inherit shellHook;
        packages =
          enabledPackages
          ++ [ package ]
          ++ (with pkgs.buildPackages; [
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
            python3
            ruff
            statix
            taplo
            treefmt
            ty
            typos
            yamlfmt
            yamllint
            zizmor
          ]);
      };
    };
}
