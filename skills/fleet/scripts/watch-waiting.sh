#!/bin/bash
# 返事待ちキューを定期更新で表示する。司令塔タブの監視ペイン用。
# macOS には watch(1) が無いのでループで代替する。
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
INTERVAL="${1:-30}"
HOURS="${2:-12}"

while true; do
  out=$(python3 "$DIR/waiting.py" "$HOURS" 2>&1)
  clear
  printf '%s\n' "$out"
  printf '\n\033[2m更新 %s · %ss間隔 · Ctrl-C で停止\033[0m\n' "$(date '+%H:%M:%S')" "$INTERVAL"
  sleep "$INTERVAL"
done
