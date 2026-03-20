#!/usr/bin/env bash
# Restore important context after compaction
# Called as PostCompact hook
#
# Injects critical information that should survive context compression.
# Returns JSON with a message to be added to the conversation.

set -euo pipefail

# Check for progress.txt (used during long tasks)
if [ -f "progress.txt" ]; then
  PROGRESS=$(cat progress.txt | head -20)
  echo "{\"result\":\"Context restored. Current progress:\\n$PROGRESS\"}"
  exit 0
fi

# No special context to restore
exit 0
