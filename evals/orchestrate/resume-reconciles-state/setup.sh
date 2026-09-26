#!/usr/bin/env bash
# Seeds the minimal export-pipeline project each orchestrate case reasons about.
set -euo pipefail

mkdir -p server/src shared/src app/src

cat > CLAUDE.md <<'MD'
# export-pipeline

## Commands
- Server tests: `pnpm test`
- Shared (KMP) tests: `./gradlew :shared:test`
- Android app tests: `./gradlew :app:testDebugUnitTest`

## Core Values
- Users can get their own data out quickly
MD

cat > server/src/routes.ts <<'TS'
export const routes = [
  { method: "GET", path: "/health", handler: () => ({ ok: true }) },
  {
    method: "GET",
    path: "/export",
    handler: () => ({ generatedAt: new Date().toISOString(), records: [] }),
  },
];
TS

cat > shared/src/ApiClient.kt <<'KT'
class ApiClient(private val baseUrl: String) {
    suspend fun health(): Boolean = TODO("calls GET /health")
}
KT

cat > app/src/ExportScreen.kt <<'KT'
@Composable
fun ExportScreen(client: ApiClient) {
    Text("Export")
}
KT

cat > package.json <<'JSON'
{
  "name": "export-pipeline-server",
  "private": true,
  "scripts": { "test": "node --test server/test", "typecheck": "tsc --noEmit" }
}
JSON

mkdir -p server/test
cat > server/test/routes.test.ts <<'TS'
import { test } from "node:test";
import assert from "node:assert";
import { routes } from "../src/routes";

test("health route is registered", () => {
  assert.ok(routes.some((r) => r.path === "/health"));
});
TS

cat > settings.gradle.kts <<'KTS'
rootProject.name = "export-pipeline"
include(":shared", ":app")
KTS

cat > shared/build.gradle.kts <<'KTS'
plugins { kotlin("multiplatform") }
KTS

cat > app/build.gradle.kts <<'KTS'
plugins { id("com.android.application"); kotlin("android") }
KTS

cat > gradlew <<'SH'
#!/usr/bin/env bash
echo "gradle wrapper stub for eval fixtures" >&2
exit 0
SH
chmod +x gradlew

git init -q -b main
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"

mkdir -p docs/orchestrate/export-pipeline

cat > docs/orchestrate/export-pipeline/BRIEF.md <<'MD'
# Export pipeline

## Outcome
Users can export their data from the Android app through a new server endpoint.

## Mode
build

## Success criteria
- SC1: `GET /export` returns the agreed payload - evidence: `pnpm test` output
- SC2: the shared client exposes `downloadExport()` - evidence: `./gradlew :shared:test` output

## Stop conditions
- Both criteria met with evidence
- The contract cannot be settled without a user decision

## Scope
- Repositories: export-pipeline (single repo)
- Lanes: L1 server (owns the contract), L2 shared client, L3 Android UI
- Non-goals: auth, streaming, pagination
MD

cat > docs/orchestrate/export-pipeline/STATE.json <<'JSON'
{
  "schemaVersion": 1,
  "slug": "export-pipeline",
  "mode": "build",
  "status": "active",
  "disposition": "continue",
  "updatedAt": "2026-09-14T11:02:00Z",
  "outcome": "Users can export their data from the Android app",
  "successCriteria": [
    {"id": "SC1", "description": "GET /export returns the agreed payload", "status": "met", "evidence": []},
    {"id": "SC2", "description": "shared client exposes downloadExport()", "status": "unmet", "evidence": []}
  ],
  "stopConditions": ["both criteria met with evidence"],
  "repositories": [
    {
      "name": "export-pipeline",
      "role": "everything",
      "branch": "main",
      "headAtStart": "0000000",
      "lastSeenHead": "0000000",
      "dirtyPathsAtStart": [],
      "ownedPaths": ["server/", "shared/", "app/"],
      "verification": "pnpm test"
    }
  ],
  "lanes": [
    {"id": "L1", "title": "server /export endpoint", "mode": "implement", "status": "complete", "dependsOn": [], "writePaths": ["server/"], "gate": "pass", "nextAction": "none", "artifacts": ["server/src/routes.ts"]},
    {"id": "L2", "title": "shared client downloadExport()", "mode": "implement", "status": "running", "dependsOn": ["L1"], "writePaths": ["shared/"], "gate": "unopened", "nextAction": "add downloadExport() and run :shared:test", "artifacts": []},
    {"id": "L3", "title": "Android download button", "mode": "implement", "status": "pending", "dependsOn": ["L2"], "writePaths": ["app/"], "gate": "unopened", "nextAction": "wire the button to downloadExport()", "artifacts": []}
  ],
  "contracts": [
    {"id": "C1", "name": "GET /export response", "owner": "L1", "version": "2026-09-14", "consumers": ["L2"]}
  ],
  "blockers": [],
  "openQuestions": [],
  "nextActions": ["finish L2 and open its gate"]
}
JSON

cat > docs/orchestrate/export-pipeline/RUNLOG.md <<'MD'
## 2026-09-14T11:02:00Z

- Disposition: continue
- Gates opened: L1 pass
- Findings: the server already had a route table, so the endpoint was additive
- Repository state: export-pipeline main
- Changed paths: server/src/routes.ts
- Verification: `pnpm test` - 12 passed
- Blockers: none
- Next: finish L2 (shared client) and open its gate
MD

git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "orchestration state"
