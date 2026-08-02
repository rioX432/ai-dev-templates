---
name: fleet
description: cmuxの全ペインを1箇所から統率する司令塔。返事待ちのエージェントを集約し、番号で指すだけで返信でき、状態・ブランチ・PRを一覧し、新しい作業ペインを立てる。「全体どうなってる」「1に返事」「#4431進めて」「Avvy系止めて」で起動する。
---

# fleet — cmux 司令塔

複数ペインで並列に走るエージェントを、**1箇所で把握し、1箇所から動かす**。

## 設計の前提（2026-08-02 の実測。詳細は `~/workspace/docs/zero-base/workspace/ai-agent-multiplex-2026/`）

- 並列度の天井を作っているのは「**指示出しと状態把握のためにタブを開く動作**」であって、承認待ち時間ではない（承認待ちは87日で実質4.8時間・中央値1秒）
- 待ち時間が短いのは **rio が張り付いているから**。張り付いているから1〜4並列（稼働時間の71.4%）から上がらない
- 起動時に決めた常設タブ構成は**実作業の56%しか当たっていない**（44%は汎用タブでcd）
- **タブは置き換えない。上に重ねる。** rio は基本タブを見ない。見るのは司令塔タブだけ

---

## 1. 司令塔タブの構成（3ペイン）

```
┌──────────────────────────┬─────────────────────┐
│ agent-witness top        │                     │
│  稼働中セッション         │   🎛 司令塔          │
├──────────────────────────┤   対話・指示出し     │
│ watch-waiting.sh         │                     │
│  返事待ちキュー(30s更新)  │                     │
└──────────────────────────┴─────────────────────┘
```

```bash
# 左上
agent-witness top
# 左下
~/.claude/skills/fleet/scripts/watch-waiting.sh 30 12
```

---

## 2. ★返事待ちキュー（このスキルの中核）

### なぜ stop を見るのか

**cmux Feed は使わない。** Feed が actionable として扱うのは `permissionRequest` / `ExitPlanMode` / `AskUserQuestion` の3種だけで、**実測では stop の 1/19 しかない**（直近45分で stop 36件 vs permissionRequest 4件）。

エージェントが「**どうしますか。**」と普通の文章で聞いて止まる場合、**Feed には出ない**（hookが発火しない）。rio が返事を求められる場面の大半はこちら。

**ターン終了 = 人間の番**、を素直に拾うのが `stop`。

### 取得

```bash
~/.claude/skills/fleet/scripts/waiting.py 12          # 人が読む形式
~/.claude/skills/fleet/scripts/waiting.py 12 --json   # 司令塔が読む形式（project/surface/said/asked/age_min）
```

出力例:
```
🎛 返事待ち  2件   (直近12時間)
 1. kakimato                     2分前   surface:21
    言った: 両アームを触り比べて体感差があるか…どうしますか
    依頼  : 計測方法どうする？
 2. viral-loc-monorepo/nine     18分前   surface:20
    言った: ビルド完了を待っています。起動したら「復元」を押して…
    依頼  : 通知の件
```

### 内部の解決チェーン（壊れたらここを疑う）

```
workstream.jsonl の kind:"stop"
  └ context.assistantPreamble = 何を言ったか（「〜の件です」がここに入る）
  └ context.lastUserMessage   = 何を頼まれたか
  └ workstreamId = "claude-<sessionId>"
       └ ~/.cmuxterm/claude-hook-sessions.json の activeSessionsBySurface
            └ surface UUID
                 └ cmux tree --all --id-format both
                      └ surface:NN   ← 返信先
```

### 必ず守ること

- **返信先が現存するものだけ残す**（`cmux tree` で解決できた surface のみ）。stop はセッションを閉じても記録に残るため、絞らないと**閉じたセッションの最後の発言が永久に居座る**（実際に3件居座り、返信先が存在しなかった）。
  ⚠️ **`agent-witness ls --live` で絞ってはいけない**。`--live` は "started, **not stopped**" を意味するので、**stop したセッション = まさに返事待ちのセッションが必ず除外される**（これで agent-witness 自身の完了報告を取りこぼした）。`activeSessionsBySurface` 全体もダメ（過去の登録が残る）
- **worktree のパスを解決する**。`/kakimato/.claude/worktrees/agent-a1441…` の末尾を取ると無意味なIDになる。リポ名は `.claude/worktrees/` の**手前**にある
- **重複を除去する**。複数の Stop hook（rio設定2つ＋cmux注入3つ）が同一ターンを二重記録する

---

## 3. ★返信フロー（番号で指すだけ）

```
rio > 1 に「触り比べた。差は感じない」

司令塔:
  1. waiting.py --json で該当行を特定 → surface:21
  2. mcp__cmux__send_input(surface="surface:21", text="触り比べた。差は感じない", press_enter=false)
  3. mcp__cmux__send_key(surface="surface:21", key="return")
  4. 「surface:21 へ送信しました」と報告
```

- **宛先は打たせない。** 番号で足りる
- 中身を確認したいと言われたら `read_screen(surface, scrollback=true)` で全文を出す
- `surface` が `(ペイン消失)` の行には返信できない。**その旨を伝える**

**送信は2段階必須。** `press_enter=true` の1段階は対話プログラム相手だと不安定（公式が明記、実測でも確認）。

---

## 4. 状態の収集

**画面パースに依存しないこと。** `read_screen` の `parsed` は実測で3回中1回しか成功しない（稼働中でも `status:"idle"`、`model:null` を返す）。

```bash
agent-witness top    # 常時更新の監視ビュー（0.0.7 で worktree のリポ名解決が入った）
agent-witness ls     # 記録されている全セッション（--live は "not stopped" なので返事待ちの判定には使えない）
```
```
mcp__cmux__list_surfaces(include_screen_preview=true, preview_lines=3)
  → title（cmuxの hooks claude auto-name が自動更新）
  → current_directory / screen_preview（ブランチ・PR番号・サブエージェント稼働）
  → resume_binding.checkpoint_id（= sessionId）
```

✅ **`agent-witness` 0.0.7 で worktree のリポ名解決が入った**（2026-08-02リリース）。`agent-a1441aa58313b993f` ではなく `kakimato` と表示される。0.0.6 以前を使っている環境では `list_surfaces` か `waiting.py` からプロジェクト名を取ること。

### 表示形式

毎回**同じ列・同じ順序**で、**行番号を振って**出す。「3 マージして」で指せるようにするのが目的。

```
#  スペース              作業                     ブランチ/PR        状態
1  viral-loc             #937 削除シートoverflow  main               sub 2体 (24分)
2  kakimato              iOSネイティブ改修        feat/92-kakimato   idle
3  persona-ios           PGR-10134 修正           fix/PGR-10134  PR#4500  idle
```

---

## 5. 宛先の解決（手入力を最小化）

| 方式 | 例 |
|---|---|
| **① 番号** | 「3 マージして」「1 に返事」 |
| **② 識別子から逆引き** | 「#4431 進めて」「PR #4500 見せて」— Issue/PR/ブランチ名は宛先を含む |
| **③ 省略＝直前を継続** | 「終わったら報告して」 |
| **④ グループ** | 「Avvy系ぜんぶ止めて」 |
| ⑤ 明示 | 「viral-loc で dev-all」 |

グループは cwd から自動判定:
```
Avvy系     = ~/workspace/src/AnotherBall/*
Projects系 = ~/workspace/projects/*
Docs系     = ~/workspace/docs/*
```

**既定の宛先は persona-android**（rio のメイン）。特定できない指示はそこへ向ける。

---

## 6. 新しい作業を立てる

⚠️ **`mcp__cmux__spawn_agent` と `mcp__cmux__new_split` は使えない**（`method_not_found`）。ツール定義は存在するが cmux サーバー側に未実装。`capabilities` の RPC 一覧にも `agent.spawn` は無い（あるのは `agent.resolve_delivery_target` / `surface.respawn`）。

**CLI 経由で立てる**（実測で4回成功）:

```bash
CMUX=/Applications/cmux.app/Contents/Resources/bin/cmux
export CMUX_SOCKET_MODE=allowAll
out=$($CMUX workspace create --cwd "$DIR"); ws=$(echo "$out" | awk '{print $2}')
$CMUX workspace rename "$ws" --title "<仮の名前>"
sf=$($CMUX tree --workspace "$ws" | grep -o 'surface:[0-9]*' | head -1)
$CMUX send --workspace "$ws" --surface "$sf" "cd $DIR && claude\n"
# 起動を read_screen で確認してから
mcp__cmux__send_input(surface=sf, text="<プロンプト>", press_enter=false)
mcp__cmux__send_key(surface=sf, key="return")
```

- **タブ名は付けなくてよい**。cmux の `hooks claude auto-name` が作業内容に自動更新する（実測: 送信後すぐ「Fix worktree path to repository name resolution」に変わった）
- 分割ペインが要るときは `cmux new-split left|right|up|down --workspace <ws> --surface <sf>`
- この方法で立てたペインは `list_agents` に登録されないため `send_to_agent` / `wait_for_all` は使えない。**`send_input` + `send_key` で代替する**

---

## 7. スキルの自動選択

**「開発して」と言われたら `dev` が走る。** ただしプロジェクトごとにスキルは全く違う。**起動時に `ls <project>/.claude/skills/` で再列挙すること。**

2026-08-02 時点の分布（参考。必ず再列挙する）:

| プロジェクト | 主なスキル |
|---|---|
| persona-android (20) | `dev` `review` `create-pr` `decompose` `dig` `investigate` `write-unit-test` `write-ui-test` `edge-to-edge` `r8-analyzer` ほか |
| persona-ios (16) | `deploy-adhoc` `deploy-devices` `deploy-simulators` `apply-ui-tags` `ios-debugger-agent` `unit-test-runner` ほか |
| persona-domain-kmm (7) | `openapi-schema-add/update/consume` `create-unit-tests` `review` |
| persona-server (2) | `spec` `triage-dependabot-prs` |
| viral-loc-monorepo (23) | ai-dev系＋`loc-discover` `loc-evaluate` `distribute-all` `release-build-and-upload` |
| CivitDeck (17) / agent-witness (11) | ai-dev系 |
| zero-base (2) | `think` `auto-research` |

**`persona-android` に `dev-all` は存在しない。** 同じ `dev` でも中身が違う。存在しないスキルを指示されたらカタログから代替を提示する。

### 選択の3層（境界は「内向きか外向きか」）

| 層 | 判断 | 例 |
|---|---|---|
| **1. 即実行** | 候補が1つ、内向き・可逆 | 「#4431 開発して」→ android の `dev` |
| **2. 引数で決まる** | 引数が選ぶ | Issue 1件→`dev` / 複数→`dev-all` |
| **3. 確認を挟む** | **外向き・不可逆** | 「デプロイして」「PR出して」「リリースして」 |

既存ルール（`git push` は明示指示がない限り実行しない／外向き作業は都度確認）と同じ線。

### スキルは「契約」ではなく「入口」

実測: rio は `/review` と打って実装を頼み、`/dev` と打ってチケット整理を頼んでいる。**これは正常な運用**。乖離を違反として報告しないこと（真の違反率は3.1%で大規模ゼロ）。

ただし rio の基準:
> 「レビューさせて、その後レビュー結果を受けて修正するのは妥当」

**スキルのコア（レビューなら検証行為）は走るべき。その後の派生作業は自由。**

---

## 8. 報告の回収

**画面経由のデリミタ抽出は使わない。** `read_agent_output(tag="REPORT")` は実測で3件とも `found:false`（出力が長く `REPORT_START` が画面バッファ外へ流れる）。

**ファイルに書かせる**:
```
指示に含める: 「報告は <共有パス>/report-<識別子>.md に書いてください」
回収:          Read で読む
```

---

## 9. サイドバーへの書き戻し

集約しても**空間的記憶を壊さない**ために、司令塔がドメイン単位の状態を返す。

```
mcp__cmux__set_status(workspace="workspace:8", key="待ち", value="2件", icon="🔴", color="#C0392B")
mcp__cmux__set_progress(workspace="workspace:8", value=0.25, label="withme 1/4")
```

タブ名は `auto-name` が自動更新するので通常は触らない。

---

## 10. 一日の締め

閉じる前に**守るべきものを先に出す**。セッションを閉じても作業内容は git に残るが、未pushのブランチはマシン故障で失われる。

```bash
for d in <各リポ>; do
  git -C "$d" rev-parse --abbrev-ref HEAD
  git -C "$d" status --porcelain | wc -l          # 未コミット
  git -C "$d" rev-list --count @{u}..HEAD         # 未push（エラーなら upstream 無し＝危険）
done
```

報告の形:
```
⚠️ pocket-mate: feat/75-ui-v2-design-foundation が未push（upstream無し）→ push しますか
⚠️ zero-base:   26ファイル未コミット
✅ avvy-qa-tamperer: clean。閉じて問題なし
✅ viral-loc: 変更4件はワーキングツリーに残るので閉じても消えない
```

翌朝の「昨日の続き」は **agent-witness ではなく git + Issue から再構成する**。`digest` は「何をしたか」は出せるが「終わったか未完か」を判定できない。git ならセッションが消えても同じ提案が出る。

---

## 11. やらないこと（今日の実測で否定されたもの）

- **cmux Feed を返事待ちの主線にしない** — stop の1/19しか拾わない。承認専用
- **`read_screen` の `parsed` に依存した状態判定** — 3回中1回しか成功しない
- **Agent Teams への依存** — cmux上で動く（teammateがペインとして生える）が、**mailboxが6分半で1件も届かない**。research preview
- **`read_agent_output` のデリミタ抽出** — 長い出力で失敗する
- **スキル名と実作業の乖離を違反として報告すること** — 正常な運用
- **生存判定なしの stop 一覧** — 閉じたセッションの残骸が永久に居座る
- **1タブへの全面集約** — サイドバーの空間的記憶が死ぬ。重ねるのが正解
- **破壊的・外向き操作の自動実行** — push / デプロイ / リリース / Issue起票は必ず確認

---

## 12. 効果の測り方

**待ち時間は増えても構わない**（張り付きを解くのが目的）。見るのは次の2つ。

```
割り込み回数     現在値 1日約21回        ← workstream.jsonl の permissionRequest + question を日割り
実効並列度       現在値 1〜4並列で71.4%   ← セッションの開始/終了から同時稼働数を算出
```

追加で見るとよいもの:
- **タブを開いた回数**（司令塔で済んだか、結局開いたか）
- **司令塔が宛先を間違えた回数**（誤送信は実害。最初の数日は送信前に宛先を1行で確認する）

計測スクリプト: `~/.claude/skills/fleet/scripts/`
- `waiting.py` — 返事待ちキュー
- `watch-waiting.sh` — 30秒更新の監視ペイン用
- `measure_skill_conformance.py` — スキル実行区間ごとのサブエージェント起動
</content>
