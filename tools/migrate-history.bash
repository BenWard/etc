#!/usr/bin/env bash

set -euo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/atuin"
if ! command -v atuin >/dev/null 2>&1; then
  echo "migrate-history: atuin is not on PATH; install it before running this task" >&2
  exit 1
fi

mkdir -p "$DATA_DIR"

import_bash() {
  local SENTINEL="$DATA_DIR/.bash-imported"
  if [[ -f "$SENTINEL" ]]; then
    echo "migrate-history: bash already imported"
    return
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

  if [[ "$LINES" -eq 0 ]]; then
    echo "migrate-history: no bash history found to import; marking sentinel"
    touch "$SENTINEL"
    return
  fi

  echo "migrate-history: importing $LINES lines of bash history into atuin"
  HISTFILE="$TMPFILE" atuin import bash

  touch "$SENTINEL"
  echo "migrate-history: done"
}

import_bash

# A Bash marker must not suppress a later zsh import. Do not mark absent files.
ZSH_SENTINEL="$DATA_DIR/.zsh-imported"
ZSH_HISTORY="${ZDOTDIR:-$HOME}/.zsh_history"
if [[ -f "$ZSH_SENTINEL" ]]; then
  echo "migrate-history: zsh already imported"
elif [[ -s "$ZSH_HISTORY" ]]; then
  echo "migrate-history: importing zsh history"
  HISTFILE="$ZSH_HISTORY" atuin import zsh
  touch "$ZSH_SENTINEL"
else
  echo "migrate-history: no zsh history found; import remains pending"
fi
