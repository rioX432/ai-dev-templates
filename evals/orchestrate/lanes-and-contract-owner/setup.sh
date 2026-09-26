#!/usr/bin/env bash
# Three independent repositories checked out side by side - the shape that actually justifies fan-out.
set -euo pipefail

seed_repo() {
  local dir="$1" ; shift
  local cmd="$1" ; shift
  mkdir -p "$dir"
  cat > "$dir/CLAUDE.md" <<MD
# $dir

## Commands
- Tests: \`$cmd\`

## Core Values
- Users can get their own data out quickly
MD
  ( cd "$dir" && git init -q -b main && git add -A \
    && git -c user.email=eval@example.com -c user.name=eval commit -qm "initial" )
}

mkdir -p export-server/src export-server/test
cat > export-server/src/routes.ts <<'TS'
export const routes = [
  { method: "GET", path: "/health", handler: () => ({ ok: true }) },
  { method: "GET", path: "/profile", handler: () => ({ id: "u1" }) },
];
TS
cat > export-server/test/routes.test.ts <<'TS'
import { test } from "node:test";
import assert from "node:assert";
import { routes } from "../src/routes";

test("health route is registered", () => {
  assert.ok(routes.some((r) => r.path === "/health"));
});
TS
cat > export-server/package.json <<'JSON'
{ "name": "export-server", "private": true, "scripts": { "test": "node --test test" } }
JSON

mkdir -p export-shared/src
cat > export-shared/src/ApiClient.kt <<'KT'
class ApiClient(private val baseUrl: String) {
    suspend fun health(): Boolean = TODO("calls GET /health")
    suspend fun profile(): Profile = TODO("calls GET /profile")
}
KT
cat > export-shared/settings.gradle.kts <<'KTS'
rootProject.name = "export-shared"
KTS
cat > export-shared/gradlew <<'SH'
#!/usr/bin/env bash
echo "gradle wrapper stub" >&2
exit 0
SH
chmod +x export-shared/gradlew

mkdir -p export-app/src
cat > export-app/src/ExportScreen.kt <<'KT'
@Composable
fun ExportScreen(client: ApiClient) {
    Text("Export")
}
KT
cat > export-app/settings.gradle.kts <<'KTS'
rootProject.name = "export-app"
KTS
cat > export-app/gradlew <<'SH'
#!/usr/bin/env bash
echo "gradle wrapper stub" >&2
exit 0
SH
chmod +x export-app/gradlew

seed_repo export-server "npm test"
seed_repo export-shared "./gradlew test"
seed_repo export-app "./gradlew testDebugUnitTest"
