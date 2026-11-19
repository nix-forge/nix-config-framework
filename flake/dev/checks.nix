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
