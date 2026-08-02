#!/usr/bin/env python3
"""返事待ちキュー — 「人間の番」になっているエージェントを一覧し、返信先まで解決する。

なぜ stop を見るのか:
  cmux Feed が actionable として扱うのは permissionRequest / ExitPlanMode / AskUserQuestion の
  3種だけで、実測では stop の 1/19 しかない。エージェントが「どうしますか。」と普通の文章で
  聞いて止まる場合は Feed に出ない。ターン終了 = 人間の番、を素直に拾うのが stop。

返信先の解決チェーン:
  workstream.jsonl の stop → workstreamId "claude-<sessionId>"
    → claude-hook-sessions.json の activeSessionsBySurface で surface UUID
      → cmux tree --id-format both で surface:NN

使い方:
  waiting.py [時間] [--json]
"""
import json, re, sys, subprocess, datetime as dt

WORKSTREAM = "/Users/rio/.cmuxterm/workstream.jsonl"
HOOK_SESSIONS = "/Users/rio/.cmuxterm/claude-hook-sessions.json"
CMUX = "/Applications/cmux.app/Contents/Resources/bin/cmux"

args = [a for a in sys.argv[1:] if not a.startswith("--")]
AS_JSON = "--json" in sys.argv
MAX_AGE_H = float(args[0]) if args else 12.0


"""絞り込みの判定について。

stop はセッションを閉じても記録に残るため、絞らないと閉じたセッションの最後の発言が
永久に居座る（実際に3件居座り、返信先が存在しなかった）。ただし絞り方を2回間違えた:

  ✗ `agent-witness ls --live` — --live は "started, not stopped" なので、stop した
    セッション = まさに返事待ちのセッションが必ず除外される（agent-witness 自身の
    完了報告を取りこぼした）
  ✗ claude-hook-sessions.json の activeSessionsBySurface 全体 — 過去の登録も残って
    いるため、閉じたペインが「返事待ち」として出る

  ✓ surface_map() の結果（= cmux tree に現存する surface と突き合わせたもの）だけを
    残す。これは「返信先が実在する」ことと同義。
"""


def surface_map():
    """sessionId -> "surface:NN" 。"""
    try:
        hooks = json.load(open(HOOK_SESSIONS))
    except Exception:
        return {}
    by_surface = hooks.get("activeSessionsBySurface") or {}
    sid_by_uuid = {}
    for surf_uuid, v in by_surface.items():
        if isinstance(v, dict) and v.get("sessionId"):
            sid_by_uuid[surf_uuid.upper()] = v["sessionId"]
    try:
        tree = subprocess.run([CMUX, "tree", "--all", "--id-format", "both"],
                              capture_output=True, text=True, timeout=20).stdout
    except Exception:
        return {}
    out = {}
    for line in tree.splitlines():
        m = re.search(r"(surface:\d+)\s+([0-9A-Fa-f-]{36})", line)
        if not m:
            continue
        ref, uuid = m.group(1), m.group(2).upper()
        sid = sid_by_uuid.get(uuid)
        if sid:
            out[sid] = ref
    return out


def parse(s):
    try:
        return dt.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return None


def project(cwd):
    """worktree のパスから本来のリポ名を復元する。
    `.claude/worktrees/<id>/...` の末尾を取ると `agent-a1441aa58313b993f` になり読めない。"""
    p = (cwd or "?").rstrip("/")
    if "/.claude/worktrees/" in p:
        base, rest = p.split("/.claude/worktrees/", 1)
        repo = base.split("/")[-1]
        tail = rest.split("/")[1:]
        return f"{repo}/{'/'.join(tail)}" if tail else repo
    return p.split("/")[-1]


def clean(s, n):
    return " ".join((s or "").split())[:n]


SURFACE = surface_map()

last = {}
with open(WORKSTREAM, "rb") as f:
    for raw in f:
        try:
            d = json.loads(raw.decode("utf-8", "replace"))
        except Exception:
            continue
        t = parse(d.get("createdAt") or "")
        if not t:
            continue
        wid = d.get("workstreamId")
        if wid not in last or t >= last[wid][0]:
            last[wid] = (t, d.get("kind"), d.get("cwd"), d.get("context") or {})

now = dt.datetime.now(dt.timezone.utc).replace(tzinfo=None)
rows, seen = [], set()
for wid, (t, kind, cwd, ctx) in sorted(last.items(), key=lambda x: x[1][0]):
    if kind != "stop":
        continue
    age = (now - t).total_seconds() / 60
    if age > MAX_AGE_H * 60:
        continue
    sid = (wid or "").replace("claude-", "")
    if SURFACE and sid not in SURFACE:   # 返信先が現存するものだけ
        continue
    key = (project(cwd), clean(ctx.get("assistantPreamble"), 40))
    if key in seen:          # 複数の Stop hook が同一ターンを二重記録する
        continue
    seen.add(key)
    rows.append({
        "project": project(cwd), "cwd": cwd, "session": sid,
        "surface": SURFACE.get(sid), "age_min": round(age, 1),
        "said": clean(ctx.get("assistantPreamble"), 300),
        "asked": clean(ctx.get("lastUserMessage"), 200),
    })
rows.sort(key=lambda r: r["age_min"])

if AS_JSON:
    print(json.dumps(rows, ensure_ascii=False, indent=1))
    sys.exit(0)

print(f"🎛 返事待ち  {len(rows)}件   (直近{MAX_AGE_H:g}時間)")
print("─" * 100)
for i, r in enumerate(rows, 1):
    ago = f"{r['age_min']:.0f}分前" if r["age_min"] < 90 else f"{r['age_min']/60:.1f}時間前"
    dest = r["surface"] or "(ペイン消失)"
    print(f"{i:2}. {r['project']:<26} {ago:>9}   {dest}")
    print(f"    言った: {clean(r['said'], 62)}")
    print(f"    依頼  : {clean(r['asked'], 34)}")
if not rows:
    print("   （全エージェントが作業中、または待ちなし）")
print("─" * 100)
