_: {
  perSystem =
    { pkgs, ... }:
    let
      source = pkgs.lib.fileset.toSource {
        root = ../..;
        fileset = pkgs.lib.fileset.unions [
          ../../pyproject.toml
          (pkgs.lib.fileset.fileFilter (file: file.hasExt "py" || file.hasExt "pyi") ../..)
        ];
      };
    in
    {
      checks.release-workflow = pkgs.runCommand "framework-release-workflow-tests" {
        sourcePath = pkgs.lib.fileset.toSource {
          root = ../..;
          fileset = pkgs.lib.fileset.unions [
            ../../.github/tests
            ../../.github/workflows/release.yml
          ];
        };
        nativeBuildInputs = [
          pkgs.python3
          pkgs.git
          pkgs.bash
          pkgs.coreutils
        ];
      } (builtins.readFile ./scripts/release-workflow-tests.sh);
      checks.python-quality = pkgs.runCommand "framework-python-quality" {
        sourcePath = source;
        nativeBuildInputs = [
          pkgs.python3
          pkgs.ruff
          pkgs.ty
        ];
      } (builtins.readFile ./scripts/python-quality.sh);
    };
}
