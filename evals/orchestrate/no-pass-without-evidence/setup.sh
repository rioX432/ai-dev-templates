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

git init -q
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"
