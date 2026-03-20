#!/usr/bin/env bash
# Log failure patterns for harness improvement
# Called as StopFailure hook
#
# Records failure details to logs/failures/ for later analysis.
# Human reviews these logs and promotes patterns to rules/*.md

set -euo pipefail

INPUT=$(cat)

# Extract failure reason
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create logs directory if needed
LOG_DIR="logs/failures"
mkdir -p "$LOG_DIR"

# Write failure log
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).jsonl"
echo "{\"timestamp\":\"$TIMESTAMP\",\"reason\":\"$REASON\"}" >> "$LOG_FILE"

exit 0
