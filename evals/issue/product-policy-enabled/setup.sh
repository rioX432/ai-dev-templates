#!/usr/bin/env bash
# A product repository that has opted into the provider's product policy.
set -euo pipefail

mkdir -p src/asr

cat > AGENTS.md <<'MD'
# live-caption

Desktop overlay that shows real-time translated captions during meetings.

## Product policy

core-value-filter

## Core Values

1. Accurate real-time translation of spoken meetings

## Won't Do

- **AI meeting summaries**: summarizing is not translating; indirect benefit only

## Commands

```text
test: pnpm test        # success: "Tests: N passed, 0 failed"
```

## Architecture

- `src/asr/` streams audio to the speech model; `src/asr/stream.ts` reloads the model per utterance.
MD

cat > src/asr/stream.ts <<'TS'
export async function transcribe(chunk: ArrayBuffer, load: () => Promise<Model>): Promise<string> {
  const model = await load();
  return model.run(chunk);
}
interface Model { run(chunk: ArrayBuffer): Promise<string> }
TS

git init -q
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"
