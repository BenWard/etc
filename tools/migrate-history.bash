#!/usr/bin/env bash

set -euo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/atuin"
SENTINEL="$DATA_DIR/.bash-imported"

if [[ -f "$SENTINEL" ]]; then
  echo "migrate-history: already imported (sentinel: $SENTINEL)"
  exit 0
fi

if ! command -v atuin >/dev/null 2>&1; then
  echo "migrate-history: atuin is not on PATH; install it before running this task" >&2
  exit 1
fi

TMPFILE=$(mktemp -t atuin-bash-import.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

if [[ -s "$HOME/.bash_history" ]]; then
  cat "$HOME/.bash_history" >> "$TMPFILE"
fi

# macOS per-session history shards.
shopt -s nullglob
for f in "$HOME"/.bash_sessions/*.history; do
  [[ -s "$f" ]] && cat "$f" >> "$TMPFILE"
done
shopt -u nullglob

LINES=$(wc -l < "$TMPFILE" | tr -d ' ')

mkdir -p "$DATA_DIR"

if [[ "$LINES" -eq 0 ]]; then
  echo "migrate-history: no bash history found to import; marking sentinel"
  touch "$SENTINEL"
  exit 0
fi

echo "migrate-history: importing $LINES lines of bash history into atuin"
HISTFILE="$TMPFILE" atuin import bash

touch "$SENTINEL"
echo "migrate-history: done"
