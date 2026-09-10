"""Run the portable manage-adr create-adr.sh regression harness."""

from __future__ import annotations

import subprocess
from pathlib import Path


def test_create_adr_script() -> None:
    """Shell harness must exit 0 (stubs adr-tools; no network)."""
    repo_root = Path(__file__).resolve().parents[3]
    harness = repo_root / ".claude" / "skills" / "manage-adr" / "scripts" / "test-create-adr.sh"
    assert harness.is_file(), f"missing harness: {harness}"
    result = subprocess.run(
        ["bash", str(harness)],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, (
        f"test-create-adr.sh failed ({result.returncode})\n"
        f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
    )
