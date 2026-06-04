#!/usr/bin/env bash

set -u

branch=${1:-$(git branch --show-current)}

if [[ -z "$branch" ]]; then
  echo "No branch specified and current HEAD is detached." >&2
  exit 1
fi

root=$(git rev-parse --show-toplevel)
name=$(printf '%s' "$branch" | tr / -)
path="$root/.worktrees/$name"

if [[ $# -eq 0 ]]; then
  git worktree add --force "$path" "$branch"
else
  git worktree add -b "$branch" "$path"
fi
