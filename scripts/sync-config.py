#!/usr/bin/env python3
"""Validate sync-config.json and render its GitHub Actions project matrix."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


class ConfigError(ValueError):
    pass


def string_list(value: Any, field: str) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
        raise ConfigError(f"{field} must be a list of non-empty strings")
    if len(value) != len(set(value)):
        raise ConfigError(f"{field} contains duplicates")
    return value


def require_file(path: Path, field: str) -> None:
    if not path.is_file():
        raise ConfigError(f"{field} references missing file: {path}")


def load_and_validate(config_path: Path, source_root: Path) -> dict[str, Any]:
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ConfigError(f"cannot read {config_path}: {exc}") from exc

    if config.get("schema_version") != 2:
        raise ConfigError("schema_version must be 2")

    projects = config.get("projects")
    layers = config.get("layer_types")
    if not isinstance(projects, dict) or not projects:
        raise ConfigError("projects must be a non-empty object")
    if not isinstance(layers, dict):
        raise ConfigError("layer_types must be an object")

    for skill in string_list(config.get("common_skills"), "common_skills"):
        require_file(source_root / "skills" / skill / "SKILL.md", f"common_skills.{skill}")
    for agent in string_list(config.get("common_agents"), "common_agents"):
        require_file(source_root / "agents" / f"{agent}.md", f"common_agents.{agent}")
    for rule in string_list(config.get("common_rules"), "common_rules"):
        require_file(source_root / "rules" / rule, f"common_rules.{rule}")

    for layer_name, layer in layers.items():
        if not isinstance(layer, dict):
            raise ConfigError(f"layer_types.{layer_name} must be an object")
        layer_root = source_root / "layers" / layer_name
        for agent in string_list(layer.get("agents", []), f"layer_types.{layer_name}.agents"):
            require_file(layer_root / "agents" / f"{agent}.md", f"layer_types.{layer_name}.agents.{agent}")
        for rule in string_list(layer.get("rules", []), f"layer_types.{layer_name}.rules"):
            require_file(layer_root / "rules" / rule, f"layer_types.{layer_name}.rules.{rule}")
        for skill in string_list(layer.get("skills", []), f"layer_types.{layer_name}.skills"):
            require_file(layer_root / "skills" / skill / "SKILL.md", f"layer_types.{layer_name}.skills.{skill}")
        for template in string_list(layer.get("templates", []), f"layer_types.{layer_name}.templates"):
            require_file(layer_root / "templates" / template, f"layer_types.{layer_name}.templates.{template}")

    defaults = string_list(config.get("default_adapters"), "default_adapters")
    unknown_adapters = set(defaults) - {"claude", "codex"}
    if unknown_adapters:
        raise ConfigError(f"unknown default adapters: {sorted(unknown_adapters)}")
    if "claude" not in defaults:
        raise ConfigError("default_adapters must include 'claude' during the adapter migration")
    if config.get("hook_policy") not in {"manual", "disabled"}:
        raise ConfigError("hook_policy must be 'manual' or 'disabled'")

    for project_name, project in projects.items():
        if not isinstance(project_name, str) or not project_name:
            raise ConfigError("project names must be non-empty strings")
        if not isinstance(project, dict) or not isinstance(project.get("path"), str):
            raise ConfigError(f"projects.{project_name}.path must be a string")
        project_layers = string_list(project.get("layers"), f"projects.{project_name}.layers")
        unknown_layers = set(project_layers) - set(layers)
        if unknown_layers:
            raise ConfigError(f"projects.{project_name} has unknown layers: {sorted(unknown_layers)}")
        adapters = string_list(project.get("adapters", defaults), f"projects.{project_name}.adapters")
        unknown = set(adapters) - {"claude", "codex"}
        if unknown:
            raise ConfigError(f"projects.{project_name} has unknown adapters: {sorted(unknown)}")
        if "claude" not in adapters:
            raise ConfigError(
                f"projects.{project_name}.adapters must include 'claude' during the adapter migration"
            )

    return config


def matrix(config: dict[str, Any]) -> list[dict[str, str]]:
    defaults = config["default_adapters"]
    return [
        {
            "repo": name,
            "layers": " ".join(project["layers"]),
            "adapters": " ".join(project.get("adapters", defaults)),
        }
        for name, project in config["projects"].items()
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("validate", "matrix"))
    parser.add_argument("--config", type=Path, default=Path("skills/sync/sync-config.json"))
    parser.add_argument("--source-root", type=Path, default=Path("."))
    args = parser.parse_args()
    try:
        config = load_and_validate(args.config, args.source_root.resolve())
    except ConfigError as exc:
        print(f"sync config error: {exc}", file=sys.stderr)
        return 2
    if args.command == "matrix":
        print(json.dumps(matrix(config), separators=(",", ":")))
    else:
        print(f"sync config valid: {len(config['projects'])} projects")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
