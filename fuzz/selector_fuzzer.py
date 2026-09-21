"""Fuzz selector discovery against generated Nix module trees."""

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import atheris

REPOSITORY = Path(__file__).resolve().parents[1]
DIRECTORY = tempfile.TemporaryDirectory(prefix="selector-fuzz-")
ROOT = Path(DIRECTORY.name) / "modules"


def suffix(provider: atheris.FuzzedDataProvider) -> str:
    return "".join(chr(97 + provider.ConsumeIntInRange(0, 25)) for _ in range(3))


@atheris.instrument_func
def test_one_input(data: bytes) -> None:
    provider = atheris.FuzzedDataProvider(data)
    if ROOT.exists():
        shutil.rmtree(ROOT)
    ROOT.mkdir()
    count = provider.ConsumeIntInRange(1, 8)
    expected = set()
    first_name = None
    first_is_file = False
    for index in range(count):
        name = f"entry{index}{suffix(provider)}"
        is_file = provider.ConsumeBool()
        if index == 0:
            first_name, first_is_file = name, is_file
        if is_file:
            (ROOT / f"{name}.nix").write_text("{ }: { }\n")
            expected.add(name)
        else:
            directory = ROOT / name
            directory.mkdir()
            (directory / "child.nix").write_text("{ }: { }\n")
            if provider.ConsumeBool():
                (directory / "default.nix").write_text("{ }: { }\n")
            expected.update((name, f"{name}-child"))
    (ROOT / ".hidden.nix").write_text("{ }: { }\n")
    (ROOT / "archive").mkdir()
    (ROOT / "archive/ignored.nix").write_text("{ }: { }\n")
    collision = provider.ConsumeBool()
    if collision:
        if first_is_file:
            duplicate = ROOT / first_name
            duplicate.mkdir()
            (duplicate / "child.nix").write_text("{ }: { }\n")
        else:
            (ROOT / f"{first_name}.nix").write_text("{ }: { }\n")

    expression = (
        "let flake = builtins.getFlake "
        + json.dumps(str(REPOSITORY))
        + "; framework = import "
        + json.dumps(str(REPOSITORY / "lib/default.nix"))
        + " { lib = flake.inputs.nixpkgs.lib; }; in "
        + "builtins.attrNames (framework.mkModuleSet (builtins.toPath "
        + json.dumps(str(ROOT))
        + "))"
    )
    result = subprocess.run(
        ["nix", "eval", "--impure", "--json", "--expr", expression],
        check=False,
        capture_output=True,
        text=True,
        timeout=30,
    )
    if collision:
        assert result.returncode != 0
        assert "duplicate generated selector" in result.stderr
        return
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout) == sorted(expected)


if __name__ == "__main__":
    atheris.Setup(sys.argv, test_one_input)
    atheris.Fuzz()
