#!/usr/bin/env python3
"""Normalize Trivy CycloneDX JSON so Grype can decode it.

Trivy 0.71 emits CycloneDX specVersion 1.7. Grype 0.112 (via Syft) does not
recognize 1.7 and fails with \"sbom format not recognized\". Rewrite the
document to CycloneDX 1.6 in place.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

TARGET_SPEC_VERSION = "1.6"
TARGET_SCHEMA = "http://cyclonedx.org/schema/bom-1.6.schema.json"


def normalize_cyclonedx_sbom(path: Path) -> None:
    """Rewrite *path* to CycloneDX 1.6 if needed."""
    document = json.loads(path.read_text(encoding="utf-8"))
    if document.get("bomFormat") != "CycloneDX":
        raise SystemExit(f"{path}: not a CycloneDX document (bomFormat missing)")
    document["specVersion"] = TARGET_SPEC_VERSION
    document["$schema"] = TARGET_SCHEMA
    path.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    """CLI entrypoint."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "sbom_path",
        type=Path,
        help="Path to a CycloneDX JSON SBOM file to normalize in place",
    )
    args = parser.parse_args(argv)
    if not args.sbom_path.is_file():
        print(f"error: SBOM file not found: {args.sbom_path}", file=sys.stderr)
        return 1
    normalize_cyclonedx_sbom(args.sbom_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
