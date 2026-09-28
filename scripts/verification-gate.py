#!/usr/bin/env python3
"""Deterministic checks for rules/verification.md.

classify: risk signals -> verification profile.
check:    a verification record -> whether it satisfies its profile.
table:    the profile table that rules/verification.md must contain verbatim.
"""

from __future__ import annotations

import argparse
import json
import sys
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
        passing.append(item)

    required = required_tiers(profile, signals)
    # A passing broader tier covers every narrower one.
    covered_rank = max((TIER_ORDER.index(c["tier"]) for c in passing), default=-1)
    missing = [tier for tier in required if TIER_ORDER.index(tier) > covered_rank]
    for command in record.get("done_when") or []:
        if not any(c.get("command") == command for c in passing):
            missing.append(f"done_when: {command}")

    local = [c for c in checks if c.get("source", "local") == "local"]
    for item in local:
        if profile == "fast" and item.get("tier") == "full" and not item.get("required_by"):
            violations.append("fast profile ran the full suite locally without a repository or issue requirement")

    return {
        "ok": not missing and not violations,
        "profile": profile,
        "required_tiers": required,
        "missing": missing,
        "violations": violations,
        "local_command_count": len(local),
        "delegated_command_count": len(checks) - len(local),
    }


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
    args = parser.parse_args()
    try:
        if args.command == "classify":
            print(classify(args.signals))
            return 0
        if args.command == "table":
            print(table())
            return 0
        result = check(json.loads(args.record.read_text(encoding="utf-8")))
        print(json.dumps(result, indent=2))
        return 0 if result["ok"] else 1
    except (RecordError, OSError, json.JSONDecodeError) as exc:
        print(f"verification record error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
