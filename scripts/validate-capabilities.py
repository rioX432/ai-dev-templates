#!/usr/bin/env python3
"""Validate the capability manifest and resolve entries for a capability resolver.

Uses only the standard library: the schema keywords used by capabilities/schema.json
are implemented here so validation does not depend on an installed jsonschema.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

MANIFEST = Path("capabilities/manifest.json")
SCHEMA = Path("capabilities/schema.json")
PLUGIN = Path(".claude-plugin/plugin.json")

# Skills whose loop is a Control Plane or a fixed E2E composition. A resolver that
# loaded them would run a nested orchestrator, so they can never be exported.
NEVER_EXPORTED_SKILLS = {"dev", "dev-all", "orchestrate"}
STANDALONE_FOLDER = "standalone"
IGNORED_NAMES = {".DS_Store", "__pycache__"}
# Each resource type lives in exactly one top-level folder, so a wrapper cannot be
# re-exported by declaring its SKILL.md as some other resource type.
TYPE_FOLDERS = {"skill": "skills", "agent": "agents", "rule": "rules", "script": "scripts"}
WORKSPACE_LEVELS = {"none": 0, "read": 1, "write": 2}


class ManifestError(ValueError):
    pass


def check_schema(value: Any, schema: dict[str, Any], root: dict[str, Any], where: str, errors: list[str]) -> None:
    if "$ref" in schema:
        ref = schema["$ref"]
        if not ref.startswith("#/$defs/"):
            raise ManifestError(f"unsupported $ref {ref}")
        schema = root["$defs"][ref.removeprefix("#/$defs/")]

    if "const" in schema and value != schema["const"]:
        errors.append(f"{where}: must equal {schema['const']!r}")
        return
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{where}: {value!r} is not one of {schema['enum']}")
        return

    expected = schema.get("type")
    type_ok = {
        None: True,
        "object": isinstance(value, dict),
        "array": isinstance(value, list),
        "string": isinstance(value, str),
        "integer": isinstance(value, int) and not isinstance(value, bool),
        "boolean": isinstance(value, bool),
    }[expected]
    if not type_ok:
        errors.append(f"{where}: expected {expected}")
        return

    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            errors.append(f"{where}: shorter than {schema['minLength']}")
        if "pattern" in schema and not re.search(schema["pattern"], value):
            errors.append(f"{where}: {value!r} does not match {schema['pattern']}")
    if isinstance(value, int) and "minimum" in schema and value < schema["minimum"]:
        errors.append(f"{where}: below minimum {schema['minimum']}")
    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            errors.append(f"{where}: needs at least {schema['minItems']} items")
        if schema.get("uniqueItems"):
            seen = [json.dumps(item, sort_keys=True) for item in value]
            if len(seen) != len(set(seen)):
                errors.append(f"{where}: items must be unique")
        if "items" in schema:
            for index, item in enumerate(value):
                check_schema(item, schema["items"], root, f"{where}[{index}]", errors)
    if isinstance(value, dict):
        for key in schema.get("required", []):
            if key not in value:
                errors.append(f"{where}: missing required field {key!r}")
        properties = schema.get("properties", {})
        for key, item in value.items():
            if key in properties:
                check_schema(item, properties[key], root, f"{where}.{key}", errors)
            elif schema.get("additionalProperties") is False:
                errors.append(f"{where}: unknown field {key!r}")


def inside_root(root: Path, relative: str) -> Path:
    path = (root / relative).resolve()
    if not path.is_relative_to(root):
        raise ManifestError(f"{relative} resolves outside the provider root")
    return path


def resource_files(root: Path, resource: dict[str, str]) -> list[Path]:
    path = inside_root(root, resource["path"])
    if resource["type"] == "skill":
        if not (path / "SKILL.md").is_file():
            raise ManifestError(f"skill resource {resource['path']} has no SKILL.md")
        return sorted(
            p for p in path.rglob("*") if p.is_file() and not IGNORED_NAMES.intersection(p.relative_to(root).parts)
        )
    if not path.is_file():
        raise ManifestError(f"{resource['type']} resource {resource['path']} does not exist")
    return [path]


def declared_tools(skill_file: Path) -> list[str] | None:
    text = skill_file.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None
    header = text[4 : text.find("\n---\n", 4)]
    match = re.search(r"(?m)^allowed-tools:\s*\n((?:\s+- .+\n?)+)", header)
    if not match:
        return None
    return [line.strip()[2:].strip() for line in match.group(1).splitlines() if line.strip()]


def content_hash(root: Path, entry: dict[str, Any]) -> str:
    digest = hashlib.sha256()
    for resource in entry["resources"]:
        for file in resource_files(root, resource):
            relative = file.relative_to(root).as_posix()
            # Normalize CRLF so a Windows checkout with autocrlf hashes like a Unix one.
            data = file.read_bytes().replace(b"\r\n", b"\n")
            digest.update(f"{relative}\0{hashlib.sha256(data).hexdigest()}\n".encode())
    return "sha256:" + digest.hexdigest()


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ManifestError(f"cannot read {path}: {exc}") from exc


def validate(root: Path, manifest_path: Path, check_hashes: bool = True) -> dict[str, Any]:
    manifest = load_json(manifest_path)
    schema = load_json(root / SCHEMA)
    errors: list[str] = []
    check_schema(manifest, schema, schema, "manifest", errors)
    if errors:
        raise ManifestError("schema violations:\n  " + "\n  ".join(errors))

    plugin_version = load_json(root / PLUGIN).get("version")
    if manifest["provider"]["version"] != plugin_version:
        raise ManifestError(f"provider.version {manifest['provider']['version']} != plugin.json {plugin_version}")

    entries = manifest["capabilities"]
    by_id: dict[str, dict[str, Any]] = {}
    for entry in entries:
        if entry["id"] in by_id:
            raise ManifestError(f"duplicate capability id {entry['id']}")
        by_id[entry["id"]] = entry

    skill_owner: dict[str, str] = {}
    covered: set[str] = set()
    for entry in entries:
        cid = entry["id"]
        kind = entry["kind"]
        for resource in entry["resources"]:
            resource_files(root, resource)
            parts = Path(resource["path"]).parts
            for rtype, folder in TYPE_FOLDERS.items():
                if (parts[0] == folder) != (resource["type"] == rtype):
                    raise ManifestError(f"{cid}: {resource['path']} must be a '{rtype}' resource only under {folder}/")
            if resource["type"] == "skill" and len(parts) != 2:
                raise ManifestError(f"{cid}: skill resource {resource['path']} must be a skills/<name> directory")
            if parts[0] == STANDALONE_FOLDER and kind != "standalone":
                raise ManifestError(f"{cid}: {resource['path']} is standalone policy and cannot be exported")
        paths = [r["path"] for r in entry["resources"]]
        if not any(entry["entrypoint"] == p or entry["entrypoint"].startswith(p + "/") for p in paths):
            raise ManifestError(f"{cid}: entrypoint {entry['entrypoint']} is not inside its resources")
        if not inside_root(root, entry["entrypoint"]).is_file():
            raise ManifestError(f"{cid}: entrypoint {entry['entrypoint']} does not exist")
        if (kind == "standalone") != ("standalone" in entry):
            raise ManifestError(f"{cid}: the standalone block is required for, and only for, kind 'standalone'")
        if kind == "standalone" and not cid.startswith("standalone."):
            raise ManifestError(f"{cid}: standalone entries use the 'standalone.' id prefix")
        if kind != "standalone" and cid.startswith("standalone."):
            raise ManifestError(f"{cid}: the 'standalone.' prefix is reserved for standalone entries")

        for resource in entry["resources"]:
            covered.add(resource["path"])
            if resource["type"] == "skill":
                skill = Path(resource["path"]).name
                if skill in skill_owner:
                    raise ManifestError(f"skill {skill} is claimed by both {skill_owner[skill]} and {cid}")
                skill_owner[skill] = cid
                if skill in NEVER_EXPORTED_SKILLS and kind != "standalone":
                    raise ManifestError(f"{cid}: skills/{skill} is a standalone wrapper and cannot be exported")
                tools = declared_tools(root / resource["path"] / "SKILL.md")
                if tools is not None and ("Agent" in tools) != entry["authority"]["spawns_agents"]:
                    raise ManifestError(
                        f"{cid}: authority.spawns_agents disagrees with skills/{skill} allowed-tools (Agent)"
                    )

        for target in entry.get("composes", []):
            if target not in by_id:
                raise ManifestError(f"{cid}: composes unknown capability {target}")
            if target == cid:
                raise ManifestError(f"{cid}: composes itself")
            if kind != "standalone" and by_id[target]["kind"] == "standalone":
                raise ManifestError(f"{cid}: an exported entry cannot compose standalone entry {target}")
            inner = by_id[target]["authority"]
            outer = entry["authority"]
            missing = set(inner["external"]) - set(outer["external"])
            if missing:
                raise ManifestError(f"{cid}: authority.external omits {sorted(missing)} from composed {target}")
            if WORKSPACE_LEVELS[outer["workspace"]] < WORKSPACE_LEVELS[inner["workspace"]]:
                raise ManifestError(f"{cid}: authority.workspace is narrower than composed {target}")
            if inner["spawns_agents"] and not outer["spawns_agents"]:
                raise ManifestError(f"{cid}: authority.spawns_agents is false but composed {target} spawns agents")

        if check_hashes:
            actual = content_hash(root, entry)
            if entry["content_hash"] != actual:
                raise ManifestError(
                    f"{cid}: content_hash is stale (expected {actual}); "
                    "run scripts/validate-capabilities.py update-hashes and review the change"
                )

    for skill_dir in sorted((root / "skills").iterdir()):
        if (skill_dir / "SKILL.md").is_file() and skill_dir.name not in skill_owner:
            raise ManifestError(f"skills/{skill_dir.name} is not classified by any manifest entry")
    for folder in ("agents", "rules", STANDALONE_FOLDER):
        for file in sorted((root / folder).glob("*.md")):
            if f"{folder}/{file.name}" not in covered:
                raise ManifestError(f"{folder}/{file.name} is not classified by any manifest entry")

    return manifest


def exported(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    return [entry for entry in manifest["capabilities"] if entry["kind"] != "standalone"]


def strip_frontmatter(text: str) -> str:
    # Host frontmatter (allowed tools, agent model defaults) is adapter metadata that a
    # resolver overrides; the body is the context a capability contributes.
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end >= 0:
            return text[end + 5 :]
    return text


def context(root: Path, entries: list[dict[str, Any]]) -> str:
    chunks = []
    for entry in entries:
        for resource in entry["resources"]:
            for file in resource_files(root, resource):
                if file.suffix == ".md":
                    relative = file.relative_to(root).as_posix()
                    chunks.append(f"<!-- {entry['id']}: {relative} -->\n{strip_frontmatter(file.read_text(encoding='utf-8'))}")
    return "\n".join(chunks)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs="?", default="validate", choices=("validate", "update-hashes", "export", "resolve", "context"))
    parser.add_argument("capability", nargs="?", help="capability id for resolve")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--manifest", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    manifest_path = args.manifest or root / MANIFEST

    try:
        if args.command == "update-hashes":
            manifest = validate(root, manifest_path, check_hashes=False)
            for entry in manifest["capabilities"]:
                entry["content_hash"] = content_hash(root, entry)
            manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            validate(root, manifest_path)
            print("capability manifest: hashes updated")
            return 0

        manifest = validate(root, manifest_path)
        if args.command == "validate":
            print("capability manifest: OK")
        elif args.command == "context":
            print(context(root, exported(manifest)))
        elif args.command == "export":
            print(json.dumps({"provider": manifest["provider"], "capabilities": exported(manifest)}, indent=2))
        else:
            match = [entry for entry in exported(manifest) if entry["id"] == args.capability]
            if not match:
                raise ManifestError(f"{args.capability!r} is not an exported capability")
            print(json.dumps(match[0], indent=2))
    except ManifestError as exc:
        print(f"capability manifest error: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
