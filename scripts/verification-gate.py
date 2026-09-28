#!/usr/bin/env python3
"""Deterministic checks for rules/verification.md.

classify: risk signals -> verification profile.
check:    a verification record -> whether it satisfies its profile.
table:    the profile table that rules/verification.md must contain verbatim.
key:      the evidence key for one command on the current repository state.
reuse:    whether stored evidence satisfies a key, and why or why not.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

PROFILE_ORDER = ["fast", "standard", "highRisk"]
TIER_ORDER = ["focused", "affected-module", "integration", "full"]

SIGNALS = {
    "fast": ["docs-only", "comments-only", "test-only", "refactor-no-behavior-change", "config-text"],
    "standard": ["behavior-change", "new-feature", "crosses-module-boundary", "dependency-minor"],
    "highRisk": [
        "public-contract",
        "data-migration",
        "security",
        "auth",
        "concurrency",
        "build-or-ci-config",
        "dependency-major",
        "cross-repository",
        "irreversible",
    ],
}
SIGNAL_PROFILE = {signal: profile for profile, signals in SIGNALS.items() for signal in signals}

REQUIRED = {
    "fast": ["focused"],
    "standard": ["focused", "affected-module"],
    "highRisk": ["focused", "affected-module", "integration", "full"],
}
# standard adds integration only when the change alters how modules interact
CONDITIONAL = {"standard": {"crosses-module-boundary": "integration"}}
DELEGABLE = {"fast": [], "standard": ["integration"], "highRisk": ["full"]}
REQUIRED_BY = {"repository", "issue"}
# Key fields that must match exactly; the content fields are compared separately.
EXACT_KEY_FIELDS = ["tier", "command", "surface", "config", "config_fingerprint", "toolchain"]


class RecordError(ValueError):
    pass


def classify(signals: list[str]) -> str:
    if not signals:
        raise RecordError("at least one signal is required; an unclassified change has no profile")
    unknown = sorted(set(signals) - set(SIGNAL_PROFILE))
    if unknown:
        raise RecordError(f"unknown signals: {unknown}")
    return max((SIGNAL_PROFILE[s] for s in signals), key=PROFILE_ORDER.index)


def required_tiers(profile: str, signals: list[str]) -> list[str]:
    tiers = list(REQUIRED[profile])
    for signal, tier in CONDITIONAL.get(profile, {}).items():
        if signal in signals and tier not in tiers:
            tiers.append(tier)
    return sorted(tiers, key=TIER_ORDER.index)


def check(record: dict[str, Any]) -> dict[str, Any]:
    signals = record.get("signals") or []
    profile = record.get("profile")
    derived = classify(signals)
    violations: list[str] = []
    if profile not in PROFILE_ORDER:
        raise RecordError(f"unknown profile {profile!r}")
    if PROFILE_ORDER.index(profile) < PROFILE_ORDER.index(derived):
        violations.append(f"profile {profile} is lower than {derived}, which the signals require")
        profile = derived

    head = record.get("head_sha")
    if not head:
        raise RecordError("head_sha is required")
    checks = record.get("checks") or []
    passing: list[dict[str, Any]] = []
    for index, item in enumerate(checks):
        where = f"checks[{index}] ({item.get('tier')}: {item.get('command')})"
        if item.get("tier") not in TIER_ORDER:
            raise RecordError(f"{where}: unknown tier")
        if item.get("source", "local") not in {"local", "ci"}:
            raise RecordError(f"{where}: source must be local or ci")
        if item.get("head_sha") != head:
            violations.append(f"{where}: ran against {item.get('head_sha')}, not the final head {head}")
            continue
        if item.get("exit_code") != 0 or not item.get("success_signal"):
            violations.append(f"{where}: did not pass")
            continue
        if item.get("source") == "ci" and item["tier"] not in DELEGABLE[profile]:
            # CI may run more than the profile needs; it just cannot stand in for a local tier.
            continue
        if item.get("source") == "ci" and item.get("required") is not True:
            # An informational CI job can be skipped or ignored at merge, so it proves nothing.
            violations.append(f"{where}: CI check is not marked required for merge; it cannot satisfy a delegated tier")
            continue
        passing.append(item)

    required = required_tiers(profile, signals)
    # A passing broader tier covers every narrower one.
    covered_rank = max((TIER_ORDER.index(c["tier"]) for c in passing), default=-1)
    missing = [tier for tier in required if TIER_ORDER.index(tier) > covered_rank]
    for command in record.get("done_when") or []:
        if not any(c.get("command") == command for c in passing):
            missing.append(f"done_when: {command}")

    local = [c for c in checks if c.get("source", "local") == "local"]
    reused = [c for c in local if (c.get("reuse") or {}).get("decision") == "reused"]
    for item in checks:
        if "required_by" in item and item["required_by"] not in REQUIRED_BY:
            raise RecordError(f"required_by must be one of {sorted(REQUIRED_BY)}, got {item['required_by']!r}")
    for item in local:
        if profile == "fast" and item.get("tier") == "full" and not item.get("required_by"):
            violations.append("fast profile ran the full suite locally without a repository or issue requirement")

    return {
        "ok": not missing and not violations,
        "profile": profile,
        "required_tiers": required,
        "missing": missing,
        "violations": violations,
        "local_command_count": len(local) - len(reused),
        "reused_command_count": len(reused),
        "delegated_command_count": len(checks) - len(local),
    }


def git(repo: Path, *args: str, env: dict[str, str] | None = None) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, text=True, env=env, check=False
    )
    if result.returncode != 0:
        raise RecordError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def working_tree(repo: Path) -> str:
    # Write the working tree, including untracked non-ignored files, to a tree object through a
    # throwaway index so the real index and HEAD are untouched.
    with tempfile.TemporaryDirectory() as scratch:
        env = {**os.environ, "GIT_INDEX_FILE": str(Path(scratch) / "index")}
        git(repo, "read-tree", "HEAD", env=env)
        git(repo, "add", "-A", env=env)
        return git(repo, "write-tree", env=env)


def fingerprint(repo: Path, tree: str, paths: list[str]) -> str:
    listing = git(repo, "ls-tree", "-r", "--full-tree", tree, "--", *paths)
    return "sha256:" + hashlib.sha256(listing.encode()).hexdigest()


def file_fingerprint(repo: Path, paths: list[str]) -> str:
    # Configuration is often gitignored (.env, local overrides), which a tree object cannot see, so
    # hash what is on disk. A missing path is part of the key, so creating it later invalidates.
    digest = hashlib.sha256()
    for relative in paths:
        target = (repo / relative).resolve()
        if not target.is_relative_to(repo.resolve()):
            raise RecordError(f"config path {relative} is outside the repository")
        if not target.exists():
            digest.update(f"{relative}\0missing\n".encode())
            continue
        files = sorted(p for p in target.rglob("*") if p.is_file() and ".git" not in p.relative_to(repo.resolve()).parts) if target.is_dir() else [target]
        for file in files:
            name = file.relative_to(repo.resolve()).as_posix()
            digest.update(f"{name}\0{hashlib.sha256(file.read_bytes()).hexdigest()}\n".encode())
    return "sha256:" + digest.hexdigest()


def evidence_key(repo: Path, tier: str, command: str, surface: list[str], config: list[str], toolchain: list[str]) -> dict[str, Any]:
    if tier not in TIER_ORDER:
        raise RecordError(f"unknown tier {tier!r}")
    if not surface:
        raise RecordError("a surface is required; use '.' for the whole repository")
    tree = working_tree(repo)
    surface = sorted(set(surface))
    config = sorted(set(config))
    return {
        "head_sha": git(repo, "rev-parse", "HEAD"),
        "tree": tree,
        "tier": tier,
        "command": command,
        "surface": surface,
        "surface_fingerprint": fingerprint(repo, tree, surface),
        "config": config,
        "config_fingerprint": file_fingerprint(repo, config) if config else None,
        "toolchain": sorted(toolchain),
    }


def reuse(evidence: list[dict[str, Any]], key: dict[str, Any]) -> dict[str, Any]:
    candidates = [(i, e) for i, e in enumerate(evidence) if e.get("key", {}).get("command") == key["command"]]
    if not candidates:
        return {"decision": "run", "reason": "no stored evidence for this command", "evidence_index": None, "key": key}
    rejections = []
    for index, item in reversed(candidates):
        stored = item["key"]
        problems = [f"{field} changed" for field in EXACT_KEY_FIELDS if stored.get(field) != key.get(field)]
        if stored.get("surface_fingerprint") != key["surface_fingerprint"]:
            problems.append("surface content changed")
        # Within one HEAD, edits outside the surface leave this command's input unchanged. A new HEAD is
        # only the same state when it commits exactly the tree the evidence ran on.
        if stored.get("head_sha") != key["head_sha"] and stored.get("tree") != key["tree"]:
            problems.append("HEAD changed")
        if item.get("source", "local") != "local":
            problems.append("CI evidence is read from CI status, never reused from a local store")
        elif item.get("exit_code") != 0 or not item.get("success_signal"):
            problems.append("stored run did not pass")
        if not problems:
            same_head = stored.get("head_sha") == key["head_sha"]
            reason = "same HEAD and surface content" if same_head else "HEAD commits the verified tree unchanged"
            return {"decision": "reuse", "reason": reason, "evidence_index": index, "key": key}
        rejections.append(f"evidence[{index}]: " + "; ".join(problems))
    return {"decision": "run", "reason": " | ".join(rejections), "evidence_index": None, "key": key}


def table() -> str:
    rows = [
        "| Profile | Required tiers | May be delegated to CI |",
        "|---|---|---|",
    ]
    for profile in PROFILE_ORDER:
        tiers = ", ".join(REQUIRED[profile])
        for signal, tier in CONDITIONAL.get(profile, {}).items():
            tiers += f" (+ {tier} with `{signal}`)"
        delegable = ", ".join(DELEGABLE[profile]) or "—"
        rows.append(f"| `{profile}` | {tiers} | {delegable} |")
    return "\n".join(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    classify_parser = sub.add_parser("classify")
    classify_parser.add_argument("signals", nargs="*")
    check_parser = sub.add_parser("check")
    check_parser.add_argument("record", type=Path)
    sub.add_parser("table")
    key_parser = sub.add_parser("key")
    key_parser.add_argument("--repo", type=Path, default=Path("."))
    key_parser.add_argument("--tier", required=True)
    key_parser.add_argument("--command", dest="check_command", required=True)
    key_parser.add_argument("--surface", nargs="+", required=True)
    key_parser.add_argument("--config", nargs="*", default=[])
    key_parser.add_argument("--toolchain", nargs="*", default=[])
    reuse_parser = sub.add_parser("reuse")
    reuse_parser.add_argument("evidence", type=Path)
    reuse_parser.add_argument("key", type=Path)
    args = parser.parse_args()
    try:
        if args.command == "classify":
            print(classify(args.signals))
            return 0
        if args.command == "table":
            print(table())
            return 0
        if args.command == "key":
            key = evidence_key(args.repo, args.tier, args.check_command, args.surface, args.config, args.toolchain)
            print(json.dumps(key, indent=2))
            return 0
        if args.command == "reuse":
            evidence = json.loads(args.evidence.read_text(encoding="utf-8")) if args.evidence.exists() else []
            print(json.dumps(reuse(evidence, json.loads(args.key.read_text(encoding="utf-8"))), indent=2))
            return 0
        result = check(json.loads(args.record.read_text(encoding="utf-8")))
        print(json.dumps(result, indent=2))
        return 0 if result["ok"] else 1
    except (RecordError, OSError, json.JSONDecodeError) as exc:
        print(f"verification record error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
