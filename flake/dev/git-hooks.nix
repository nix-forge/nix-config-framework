{ inputs, lib, ... }: {
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem = { config, pkgs, ... }: {
    pre-commit = {
      check.enable = pkgs.stdenv.hostPlatform.isDarwin;
      settings = {
        package = pkgs.prek;
        hooks = {
          treefmt = {
            enable = true;
            name = "treefmt";
            pass_filenames = true;
            entry = "${lib.getExe config.treefmt.build.wrapper} --no-cache";
          };
          pinact = {
            enable = true;
            name = "pinact";
            entry = "${lib.getExe pkgs.pinact} run --fix=false --no-api";
            language = "system";
            files = "^\\.github/workflows/.*\\.ya?ml$";
            after = [ "treefmt" ];
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
            settings.configPath = ".typos.toml";
          };
          zizmor = {
            enable = true;
            args = [
              "--persona=pedantic"
              "--min-severity=medium"
            ];
          };
          gitleaks = {
            enable = true;
            name = "Gitleaks";
            entry = "${lib.getExe pkgs.gitleaks} git --pre-commit --staged --redact --no-banner";
            language = "system";
            always_run = true;
            pass_filenames = false;
          };
          nix-flake-check = {
            enable = true;
            name = "nix flake check (local system)";
            entry = "${lib.getExe pkgs.nix} flake check";
            always_run = true;
            pass_filenames = false;
            stages = [ "pre-push" ];
          };
        };
      };
    };
  };
}
