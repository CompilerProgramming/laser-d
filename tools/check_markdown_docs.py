#!/usr/bin/env python3
"""Validate the authoritative Laser-D Markdown specification."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
SPEC_DIR = ROOT / "spec-markdown"
INDEX = SPEC_DIR / "README.md"
FRONTMATTER_RE = re.compile(r"\A---\n(?P<body>.*?)\n---\n", re.DOTALL)
LINK_RE = re.compile(r"!?\[[^\]]*]\((?P<target>[^)\s]+)(?:\s+\"[^\"]*\")?\)")


def local_target(source: Path, raw_target: str) -> Path | None:
    target = raw_target.strip("<>")
    if (
        not target
        or target.startswith(("#", "http://", "https://", "mailto:"))
    ):
        return None
    path_text = unquote(target.split("#", 1)[0])
    if not path_text:
        return None
    return (source.parent / path_text).resolve()


def main() -> int:
    errors: list[str] = []
    markdown_files = sorted(SPEC_DIR.glob("*.md"))

    if not INDEX.is_file():
        errors.append("spec-markdown/README.md is missing")
    else:
        index_text = INDEX.read_text(encoding="utf-8")
        for path in markdown_files:
            if path == INDEX:
                continue
            if f"({path.name})" not in index_text:
                errors.append(f"{path.relative_to(ROOT)} is not linked from the index")

    for path in markdown_files:
        text = path.read_text(encoding="utf-8")

        if path != INDEX:
            if not re.search(r"(?m)^# .+", text):
                errors.append(f"{path.relative_to(ROOT)} has no level-one heading")

            match = FRONTMATTER_RE.match(text)
            if not match:
                errors.append(f"{path.relative_to(ROOT)} has no front matter")
            else:
                fields: dict[str, str] = {}
                for line in match.group("body").splitlines():
                    key, separator, value = line.partition(":")
                    if separator:
                        fields[key.strip()] = value.strip()
                for required in ("title", "status"):
                    if not fields.get(required):
                        errors.append(
                            f"{path.relative_to(ROOT)} has no {required} front-matter field"
                        )
                if fields.get("status") not in {"supported", "restricted", "rejected"}:
                    errors.append(
                        f"{path.relative_to(ROOT)} has invalid status "
                        f"{fields.get('status')!r}"
                    )
                review_sources = fields.get("review-sources")
                if review_sources:
                    for source in review_sources.split(","):
                        source = source.strip()
                        source_path = (path.parent / source).resolve()
                        if source_path.is_file():
                            continue
                        errors.append(
                            f"{path.relative_to(ROOT)} references missing "
                            f"review source {source}"
                        )

        for link in LINK_RE.finditer(text):
            target = local_target(path, link.group("target"))
            if target is not None and not target.exists():
                errors.append(
                    f"{path.relative_to(ROOT)} contains missing link "
                    f"{link.group('target')}"
                )

    if errors:
        for error in errors:
            print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"validated {len(markdown_files)} Markdown specification files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
