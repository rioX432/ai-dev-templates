#!/usr/bin/env bash
# Block direct access to sensitive files: .env, secrets, SSH keys, credentials
# Called as a PreToolUse hook for Read, Edit, Write, and Bash events
#
# Exit code 2 = block the tool call with a message
# The hook receives tool input as JSON on stdin.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)

if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
  if [ -z "$COMMAND" ]; then
    exit 0
  fi

  BASH_BLOCKED_PATTERNS=(
    "(^|[[:space:]/])\.env($|[[:space:]./])"
    "/\.ssh/"
    "(^|[[:space:]/])id_(rsa|ed25519)($|[[:space:]])"
    "\.(pem|key|p12|keystore|jks)($|[[:space:]])"
    "(service.account\.json|google-services\.json|GoogleService-Info\.plist)"
  )

  for PATTERN in "${BASH_BLOCKED_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -iqE "$PATTERN"; then
      echo "BLOCKED: Shell command references a protected secret path."
      exit 2
    fi
  done
  exit 0
fi

# Extract the file path from direct file tools.
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Patterns to block (case-insensitive matching on the file path)
BLOCKED_PATTERNS=(
  "\.env$"
  "\.env\."
  "/\.env$"
  "secret"
  "credential"
  "/\.ssh/"
  "id_rsa"
  "id_ed25519"
  "\.pem$"
  "\.key$"
  "\.p12$"
  "\.keystore$"
  "\.jks$"
  "service.account\.json"
  "google-services\.json"
  "GoogleService-Info\.plist"
)

for PATTERN in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -iqE "$PATTERN"; then
    echo "BLOCKED: Access to sensitive file detected. Pattern: '$PATTERN', File: $FILE_PATH"
    exit 2
  fi
done

exit 0
