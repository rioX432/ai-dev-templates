#!/usr/bin/env bash
# Seeds a small Gradle Android app whose CLAUDE.md names the quality gates the /goal condition must use.
set -euo pipefail

pkg=app/src/main/java/com/example/notes
tpkg=app/src/test/java/com/example/notes
mkdir -p "$pkg/auth" "$tpkg/auth"

cat > CLAUDE.md <<'MD'
# notes-android

## Commands
- Build: `./gradlew assembleDebug`
- Tests: `./gradlew test`
- Static analysis: `./gradlew detekt`

Both `./gradlew test` and `./gradlew detekt` are quality gates: a change is not done until both pass.

## Core Values
- Notes are never lost, even offline
MD

cat > settings.gradle.kts <<'KTS'
rootProject.name = "notes-android"
include(":app")
KTS

cat > app/build.gradle.kts <<'KTS'
plugins {
    id("com.android.application")
    kotlin("android")
    id("io.gitlab.arturbosch.detekt")
}
KTS

cat > gradlew <<'SH'
#!/usr/bin/env bash
echo "gradle wrapper stub for eval fixtures" >&2
exit 0
SH
chmod +x gradlew

cat > "$pkg/auth/SessionStore.kt" <<'KT'
package com.example.notes.auth

class SessionStore {
    private var token: String? = null
    private var expiresAtEpochSeconds: Long = 0

    fun save(token: String, expiresAtEpochSeconds: Long) {
        this.token = token
        this.expiresAtEpochSeconds = expiresAtEpochSeconds
    }

    fun isExpired(nowEpochSeconds: Long): Boolean = nowEpochSeconds >= expiresAtEpochSeconds

    fun clear() {
        token = null
        expiresAtEpochSeconds = 0
    }
}
KT

cat > "$tpkg/auth/SessionStoreTest.kt" <<'KT'
package com.example.notes.auth

import kotlin.test.Test
import kotlin.test.assertTrue

class SessionStoreTest {
    @Test
    fun expiredTokenIsReported() {
        val store = SessionStore()
        store.save("t", expiresAtEpochSeconds = 100)
        assertTrue(store.isExpired(nowEpochSeconds = 100))
    }
}
KT

printf 'workspace/\n.gradle/\nbuild/\n' > .gitignore

git init -q -b main
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"
