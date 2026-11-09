"""Run the publisher's real shell guards against disposable Git and release data."""

from __future__ import annotations

import hashlib
import os
import shutil
import subprocess  # ruff: ignore[suspicious-subprocess-import] - Execute reviewed workflow guards in disposable Git fixtures.
import tempfile
import textwrap
import unittest
from pathlib import Path
from typing import override

WORKFLOW = Path(__file__).parents[1] / "workflows" / "release.yml"


def _tool(name: str) -> str:
    executable = shutil.which(name)
    if executable is None:
        message = f"Release workflow fixture requires {name} in its declared PATH"
        raise RuntimeError(message)
    return executable


class ReleaseWorkflowTests(unittest.TestCase):
    """Reject unreviewed source and verify checksums beside downloaded artifacts."""

    @override
    def setUp(self) -> None:
        """Create a disposable fixture and register its cleanup."""
        self.fixture = tempfile.TemporaryDirectory()
        self.addCleanup(self.fixture.cleanup)
        self.root = Path(self.fixture.name)

    @staticmethod
    def git(directory: Path, *arguments: str) -> str:
        """Run fixed Git fixture commands using the declared executable.

        Returns:
            The command output without surrounding whitespace.

        """
        return subprocess.check_output(  # ruff: ignore[subprocess-without-shell-equals-true] - Fixed fixture arguments, not external input.
            [_tool("git"), "-C", str(directory), *arguments],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()

    def branch_fixture(self) -> tuple[Path, str, str]:
        """Create reviewed and unreviewed commits with a local clone.

        Returns:
            The checkout and the two exact commit identities.

        """
        source = self.root / "source"
        source.mkdir()
        self.git(source, "init", "-q", "--initial-branch=main")
        self.git(source, "config", "user.name", "Fixture")
        self.git(source, "config", "user.email", "fixture@example.invalid")
        self.git(source, "config", "commit.gpgsign", "false")
        self.git(source, "commit", "--allow-empty", "-qm", "reviewed")
        reviewed = self.git(source, "rev-parse", "HEAD")
        self.git(source, "checkout", "-qb", "unreviewed")
        self.git(source, "commit", "--allow-empty", "-qm", "outside main")
        unreviewed = self.git(source, "rev-parse", "HEAD")
        checkout = self.root / "checkout"
        self.git(self.root, "clone", "-q", str(source), str(checkout))
        return checkout, reviewed, unreviewed

    @staticmethod
    def guard(checkout: Path, sha: str, branch: str = "main") -> int:
        """Execute the tracked publisher guard against local fixture commits.

        Returns:
            The real workflow shell step exit status.

        """
        block = (
            WORKFLOW
            .read_text()
            .split(
                "      - name: Require release source on the protected default branch\n",
                1,
            )[1]
            .split("      - name:", 1)[0]
        )
        script = textwrap.dedent(block.split("        run: |\n", 1)[1])
        return subprocess.run(  # ruff: ignore[subprocess-without-shell-equals-true] - Execute the repository-owned workflow script with fixed fixture inputs.
            [_tool("bash"), "-c", script],
            cwd=checkout,
            env={**os.environ, "DEFAULT_BRANCH": branch, "GITHUB_SHA": sha},
            capture_output=True,
            check=False,
        ).returncode

    def test_reviewed_source_passes(self) -> None:
        """Accept the reviewed main commit."""
        checkout, reviewed, _ = self.branch_fixture()
        self.assertEqual(self.guard(checkout, reviewed), 0)

    def test_source_outside_main_fails(self) -> None:
        """Reject an existing commit outside the protected branch."""
        checkout, _, unreviewed = self.branch_fixture()
        self.assertNotEqual(self.guard(checkout, unreviewed), 0)

    def test_invalid_default_branch_fails(self) -> None:
        """Reject a branch name that traverses outside the expected ref."""
        checkout, reviewed, _ = self.branch_fixture()
        self.assertNotEqual(self.guard(checkout, reviewed, "../unreviewed"), 0)

    def test_downloaded_checksum_verifies_from_release_directory(self) -> None:
        """Verify archive bytes with the checksum beside the release artifact."""
        release = self.root / "release"
        release.mkdir()
        archive = release / "source.tar.gz"
        archive.write_bytes(b"immutable source archive fixture")
        checksum = release / "source.tar.gz.sha256"
        checksum.write_text(
            hashlib.sha256(archive.read_bytes()).hexdigest() + "  source.tar.gz\n"
        )
        script = next(
            line.strip()
            for line in WORKFLOW.read_text().splitlines()
            if "sha256sum -c" in line
        )
        result = subprocess.run(  # ruff: ignore[subprocess-without-shell-equals-true] - Execute the tracked checksum step against local fixture bytes.
            [_tool("bash"), "-c", script],
            cwd=self.root,
            env={**os.environ, "checksum": "release/source.tar.gz.sha256"},
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())


if __name__ == "__main__":
    unittest.main()
