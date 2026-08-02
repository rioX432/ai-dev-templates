#!/usr/bin/env python3
"""Step 0 v2 -- measure subagent launches per SKILL INVOCATION, not per session.

v1 counted agents per session, but a session can run for hours across dozens of
turns and contain a skill invocation as one prompt among hundreds. That inflates
"the skill spawned agents" whenever unrelated later work spawned them. Here a
skill's window runs from its own prompt to the next slash-command prompt (or the
end of the session).
"""
import json, re, subprocess, sys, collections
from concurrent.futures import ThreadPoolExecutor

SLASH = re.compile(r"^\s*/([a-zA-Z0-9_:-]+)")
# skills whose definition mandates subagents
MANDATES_AGENTS = {"think", "dev", "dev-all", "review", "audit", "competitive-audit", "ux-audit"}

def sessions():
    out = subprocess.run(["agent-witness", "ls"], capture_output=True, text=True).stdout
    rows = []
    for line in out.splitlines()[1:]:
        p = line.split()
        if len(p) < 6:
            continue
        try:
            tools = int(p[5])
        except ValueError:
            continue
        if tools > 0:
            rows.append({"id": p[0], "started": f"{p[2]} {p[3]}"})
    return rows

def windows(row):
    p = subprocess.run(["agent-witness", "report", row["id"], "--json"],
                       capture_output=True, text=True)
    if p.returncode != 0 or not p.stdout.strip():
        return []
    try:
        d = json.loads(p.stdout)
    except json.JSONDecodeError:
        return []
    tl = sorted(d.get("timeline", []), key=lambda e: e.get("offset_ms") or 0)
    end = (d.get("summary") or {}).get("duration_ms") or 0

    marks = []
    for e in tl:
        if e.get("tag") != "PROMPT":
            continue
        m = SLASH.match(e.get("summary") or "")
        if m:
            marks.append((e.get("offset_ms") or 0, m.group(1)))
    out = []
    for i, (off, cmd) in enumerate(marks):
        stop = marks[i + 1][0] if i + 1 < len(marks) else end
        span = [e for e in tl if off <= (e.get("offset_ms") or 0) < stop]
        agents = [e for e in span if e.get("tag") == "Agent"]
        tools = [e for e in span if e.get("tag") not in ("PROMPT", "STOP", "SESSION")]
        out.append({
            "session": row["id"], "started": row["started"], "cmd": cmd,
            "window_min": (stop - off) / 60000,
            "tools": len(tools),
            "agents": len(agents),
            "status": collections.Counter(a.get("status") for a in agents),
            "labels": [a.get("summary") for a in agents],
        })
    return out

rows = sessions()
print(f"sessions: {len(rows)}", file=sys.stderr)
with ThreadPoolExecutor(max_workers=12) as ex:
    res = [w for ws in ex.map(windows, rows) for w in ws]
json.dump(res, open(sys.argv[1], "w"), ensure_ascii=False)
print(f"skill invocations: {len(res)}", file=sys.stderr)
