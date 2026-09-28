#!/usr/bin/env bash
# Seeds a Gradle Android app with Core Values and quality gates, so /dev-all can pass its Step 0 gate.
set -euo pipefail

mkdir -p app/src/main/java/com/example/notes

cat > CLAUDE.md <<'MD'
# notes-android

## Commands
- Build: `./gradlew assembleDebug`
- Tests: `./gradlew test`
- Static analysis: `./gradlew detekt`

## Core Values
- Notes are never lost, even offline
- Capturing a note takes one tap

## Won't Do
- Social sharing feeds
MD

cat > settings.gradle.kts <<'KTS'
rootProject.name = "notes-android"
include(":app")
KTS

cat > app/build.gradle.kts <<'KTS'
plugins {
    id("com.android.application")
    kotlin("android")
}
KTS

cat > app/src/main/java/com/example/notes/NotesRepository.kt <<'KT'
package com.example.notes

class NotesRepository {
    private val notes = mutableListOf<String>()

    fun add(text: String) {
        notes += text
    }

    fun all(): List<String> = notes.toList()
}
KT

printf 'workspace/\n.gradle/\nbuild/\n' > .gitignore

git init -q -b main
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"
