#!/usr/bin/env bash
# Seeds the export-pipeline project mid-run: Lane A's GET /export implements v2 of the contract it owns, the client
# lane is still on v1, and nothing in the workspace shows a test run. The code matches Lane A's claim, so only
# missing evidence (not contradicting evidence) keeps the gate shut.
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
    handler: () => ({
      generatedAt: new Date().toISOString(),
      records: [{ recordId: "r1", name: "First note", updatedAt: "2026-09-20T08:00:00Z" }],
    }),
  },
];
TS

mkdir -p server/contracts
cat > server/contracts/export.md <<'MD'
# GET /export response

Owner: server lane

## v2 (current)

```json
{ "generatedAt": "ISO-8601", "records": [{ "recordId": "string", "name": "string", "updatedAt": "ISO-8601" }] }
```

## v1 (superseded by v2)

```json
{ "exportedAt": "ISO-8601", "items": [{ "id": "string", "title": "string" }] }
```
MD

cat > shared/src/ApiClient.kt <<'KT'
@Serializable
data class ExportItem(val id: String, val title: String)

@Serializable
data class ExportPayload(val exportedAt: String, val items: List<ExportItem>)

class ApiClient(private val baseUrl: String) {
    suspend fun health(): Boolean = TODO("calls GET /health")
    suspend fun downloadExport(): ExportPayload = TODO("calls GET /export")
}
KT

mkdir -p shared/test
cat > shared/test/ExportPayloadTest.kt <<'KT'
class ExportPayloadTest {
    @Test
    fun decodesExportResponse() {
        val json = """{"exportedAt":"2026-09-14T10:00:00Z","items":[{"id":"r1","title":"First note"}]}"""
        val payload = Json.decodeFromString<ExportPayload>(json)
        assertEquals("r1", payload.items.single().id)
    }
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

test("export route returns generatedAt and records", () => {
  const route = routes.find((r) => r.path === "/export");
  assert.ok(route);
  const body = route.handler() as { generatedAt: string; records: unknown[] };
  assert.ok(body.generatedAt);
  assert.ok(Array.isArray(body.records));
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
