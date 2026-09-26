#!/usr/bin/env python3
"""Render a Claude-oriented skill directory as a portable Codex Agent Skill."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


PORTABILITY_NOTE = """> **Host adaptation:** Treat product-specific tool names as capabilities. Use the
> equivalent tools available in the current host, ask through its interaction mechanism,
> and skip optional integrations that are unavailable. Resolve repository guidance from
> `AGENTS.md`, falling back to `CLAUDE.md` only when needed. `$ARGUMENTS` means the current
> user request; `${CLAUDE_SKILL_DIR}` means the directory containing this skill.
"""


def parse_portable_frontmatter(text: str) -> tuple[str, str, str]:
    if not text.startswith("---\n"):
        raise ValueError("SKILL.md must start with YAML frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("SKILL.md frontmatter is not closed")
    header = text[4:end]
    body = text[end + 5 :].lstrip("\n")

    values: dict[str, str] = {}
    for key in ("name", "description"):
        match = re.search(rf"(?m)^{key}:\s*(.+?)\s*$", header)
        if not match:
            raise ValueError(f"SKILL.md is missing {key}")
        value = match.group(1).strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'\"', "'"}:
            value = value[1:-1]
        values[key] = value
    return values["name"], values["description"], body


def yaml_quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def render(source: Path, destination: Path) -> None:
    source = source.resolve()
    destination = destination.resolve()
    skill_file = source / "SKILL.md"
    if not source.is_dir() or not skill_file.is_file():
        raise ValueError(f"not a skill directory: {source}")

    name, description, body = parse_portable_frontmatter(skill_file.read_text(encoding="utf-8"))
    if source.name != name:
        raise ValueError(f"skill directory '{source.name}' does not match name '{name}'")

    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source, destination)
    rendered = (
        "---\n"
        f"name: {name}\n"
        f"description: {yaml_quote(description)}\n"
        "---\n\n"
        f"{PORTABILITY_NOTE}\n"
        f"{body}"
    )
    (destination / "SKILL.md").write_text(rendered, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    render(args.source, args.destination)


if __name__ == "__main__":
    main()
