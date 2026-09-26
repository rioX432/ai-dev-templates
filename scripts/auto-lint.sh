#!/usr/bin/env bash
# Fast validation: checks a saved file without rewriting it
# Called as PostToolUse hook for Write/Edit events
#
# The hook receives tool input as JSON on stdin.
# Extract the file path and run the appropriate linter.

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool result
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Run the appropriate checker. PostToolUse must not race with later reads or silently
# rewrite the user's file; formatting remains an explicit workflow action.
STATUS=0
case "$EXT" in
  kt|kts)
    if command -v ktlint &>/dev/null; then
      ktlint "$FILE_PATH" || STATUS=$?
    fi
    ;;
  swift)
    if command -v swiftformat &>/dev/null; then
      swiftformat --lint "$FILE_PATH" || STATUS=$?
    fi
    ;;
  js|jsx|ts|tsx|mjs|cjs)
    if [ -f "node_modules/.bin/eslint" ]; then
      node_modules/.bin/eslint "$FILE_PATH" || STATUS=$?
    elif command -v eslint &>/dev/null; then
      eslint "$FILE_PATH" || STATUS=$?
    fi
    ;;
  py)
    if command -v ruff &>/dev/null; then
      ruff format --check "$FILE_PATH" || STATUS=$?
      ruff check "$FILE_PATH" || STATUS=$?
    elif command -v black &>/dev/null; then
      black --check "$FILE_PATH" || STATUS=$?
    fi
    ;;
  dart)
    if command -v dart &>/dev/null; then
      dart format --output=none --set-exit-if-changed "$FILE_PATH" || STATUS=$?
    fi
    ;;
  json)
    if command -v jq &>/dev/null; then
      jq empty "$FILE_PATH" || STATUS=$?
    fi
    ;;
esac

if [ "$STATUS" -ne 0 ]; then
  echo "Validation reported issues in $FILE_PATH (exit $STATUS). The file was not modified."
fi

exit 0
