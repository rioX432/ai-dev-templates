#!/usr/bin/env bash
# Seeds a small TypeScript project with one function to change and its test.
set -euo pipefail

mkdir -p src test

cat > AGENTS.md <<'MD'
# ages

## Commands
- Tests: `pnpm test`
- One file: `pnpm test -- test/age.test.ts`
MD

cat > src/age.ts <<'TS'
export function parseAge(input: string): number {
  return Number.parseInt(input, 10);
}
TS

cat > test/age.test.ts <<'TS'
import { parseAge } from "../src/age";

test("parses a whole number", () => {
  expect(parseAge("42")).toBe(42);
});
TS

git init -q
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"
