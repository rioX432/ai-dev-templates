#!/usr/bin/env bash
# Seeds a repository whose default branch is `develop` (there is no `main`) and a feature branch with 40 changed
# files: 39 committed and 1 still uncommitted. origin/HEAD is left unset, as in a repository whose remote was added
# rather than cloned; the session's git context then names `main`, so the base cannot be taken from it.
set -euo pipefail

mkdir -p src/modules

cat > src/log.ts <<'TS'
export function log(message: string): void {
  console.log(message);
}
TS

for i in $(seq -w 1 40); do
  cat > "src/modules/m$i.ts" <<TS
import { log } from "../log";

export function run$i(): void {
  log("module $i started");
}
TS
done

git init -q -b develop
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "Initial modules"
git update-ref refs/remotes/origin/develop HEAD
git checkout -qb feature/structured-logging

cat >> src/log.ts <<'TS'

export function logEvent(event: string, fields: Record<string, unknown> = {}): void {
  console.log(JSON.stringify({ event, ...fields }));
}
TS

for i in $(seq -w 1 38); do
  cat > "src/modules/m$i.ts" <<TS
import { logEvent } from "../log";

export function run$i(): void {
  logEvent("module_started", { module: "$i" });
}
TS
done

git -c user.email=eval@example.com -c user.name=eval commit -qam "Switch modules to structured logging"

cat > src/modules/m39.ts <<'TS'
import { logEvent } from "../log";

export function run39(): void {
  logEvent("module_started", { module: "39" });
}
TS
