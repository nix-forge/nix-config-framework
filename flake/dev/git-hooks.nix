{ inputs, lib, ... }: {
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem = { config, pkgs, ... }: {
    pre-commit = {
      check.enable = true;
      settings = {
        package = pkgs.buildPackages.prek;
        hooks = {
          treefmt = {
            enable = true;
            name = "treefmt";
            # treefmt schedules its formatters; avoid many concurrent wrappers.
            require_serial = true;
            pass_filenames = true;
            entry = "${lib.getExe config.treefmt.build.wrapper} --no-cache";
          };
          pinact = {
            enable = true;
            name = "pinact";
            entry = "${lib.getExe pkgs.buildPackages.pinact} run --fix=false --no-api";
            language = "system";
            files = "^\\.github/workflows/.*\\.ya?ml$";
            after = [ "treefmt" ];
          };
          ruff = {
            enable = true;
            entry = "${lib.getExe pkgs.buildPackages.ruff} check --no-fix .";
            language = "system";
            always_run = true;
            pass_filenames = false;
            after = [ "treefmt" ];
          };
          ruff-format = {
            enable = true;
            entry = "${lib.getExe pkgs.buildPackages.ruff} format --check .";
            language = "system";
            always_run = true;
            pass_filenames = false;
            after = [ "ruff" ];
          };
          ty = {
            enable = true;
            entry = "${lib.getExe pkgs.buildPackages.ty} check --project . --python ${lib.getExe pkgs.buildPackages.python3}";
            language = "system";
            always_run = true;
            pass_filenames = false;
            after = [ "ruff-format" ];
          };
          python-compile = {
            enable = true;
            name = "Python syntax";
            entry = lib.getExe (
              pkgs.buildPackages.writeShellApplication {
                name = "framework-python-syntax";
                runtimeInputs = [
                  pkgs.buildPackages.python3
                  pkgs.buildPackages.coreutils
                ];
                text = builtins.readFile ./scripts/python-syntax.sh;
              }
            );
            language = "system";
            always_run = true;
            pass_filenames = false;
            after = [ "ty" ];
          };
          end-of-file-fixer = {
            enable = true;
            after = [ "treefmt" ];
          };
          trim-trailing-whitespace = {
            enable = true;
            after = [ "treefmt" ];
          };
          mixed-line-endings = {
            enable = true;
            args = [ "--fix=lf" ];
            after = [ "treefmt" ];
          };

          check-added-large-files.enable = true;
          check-case-conflicts.enable = true;
          check-json.enable = true;
          check-merge-conflicts.enable = true;
          check-symlinks.enable = true;
          check-toml.enable = true;
          check-yaml.enable = true;
          detect-private-keys.enable = true;
          editorconfig-checker.enable = true;
          fix-byte-order-marker.enable = true;
          flake-checker.enable = true;
          typos = {
            enable = true;
            # The upstream hook's generated empty [default] table overrides configPath.
            entry = "${lib.getExe pkgs.buildPackages.typos} --config .typos.toml --force-exclude";
          };
          zizmor = {
            enable = true;
            args = [ "--persona=pedantic" ];
          };
          gitleaks = {
            enable = true;
            name = "Gitleaks";
            entry = "${lib.getExe pkgs.buildPackages.gitleaks} git --pre-commit --staged --redact --no-banner";
            # The complete entry already supplies the upstream hook arguments.
            args = [ ];
            language = "system";
            always_run = true;
            pass_filenames = false;
          };
          nix-flake-check = {
            enable = true;
            name = "nix flake check (local system)";
            # Use the Nix installation that supplies the daemon and its settings.
            # Injecting nixpkgs' CLI rejects Determinate's schemas/settings.
            entry = "nix flake check";
            always_run = true;
            pass_filenames = false;
            stages = [ "pre-push" ];
          };
        };
      };
    };
  };
}
