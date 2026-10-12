"""Run the publisher's real shell guards against disposable Git and release data."""

from __future__ import annotations

import hashlib
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

WORKFLOW = Path(__file__).parents[1] / "workflows" / "release.yml"


class ReleaseWorkflowTests(unittest.TestCase):
    """Reject unreviewed source and verify checksums beside downloaded artifacts."""

    def setUp(self) -> None:
        self.fixture = tempfile.TemporaryDirectory()
        self.addCleanup(self.fixture.cleanup)
        self.root = Path(self.fixture.name)

    def git(self, directory: Path, *arguments: str) -> str:
        return subprocess.check_output(
            ["git", "-C", str(directory), *arguments],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()

    def branch_fixture(self) -> tuple[Path, str, str]:
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

    def guard(self, checkout: Path, sha: str, branch: str = "main") -> int:
        block = (
            WORKFLOW.read_text()
            .split(
                "      - name: Require release source on the protected default branch\n",
                1,
            )[1]
            .split("      - name:", 1)[0]
        )
        script = textwrap.dedent(block.split("        run: |\n", 1)[1])
        return subprocess.run(
            ["bash", "-c", script],
            cwd=checkout,
            env={**os.environ, "DEFAULT_BRANCH": branch, "GITHUB_SHA": sha},
            capture_output=True,
            check=False,
        ).returncode

    def test_reviewed_source_passes(self) -> None:
        checkout, reviewed, _ = self.branch_fixture()
        self.assertEqual(self.guard(checkout, reviewed), 0)

    def test_source_outside_main_fails(self) -> None:
        checkout, _, unreviewed = self.branch_fixture()
        self.assertNotEqual(self.guard(checkout, unreviewed), 0)

    def test_invalid_default_branch_fails(self) -> None:
        checkout, reviewed, _ = self.branch_fixture()
        self.assertNotEqual(self.guard(checkout, reviewed, "../unreviewed"), 0)

    def test_downloaded_checksum_verifies_from_release_directory(self) -> None:
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
        result = subprocess.run(
            ["bash", "-c", script],
            cwd=self.root,
            env={**os.environ, "checksum": "release/source.tar.gz.sha256"},
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())


if __name__ == "__main__":
    unittest.main()
