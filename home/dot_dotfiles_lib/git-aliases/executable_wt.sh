#!/usr/bin/env bash

set -u

branch=${1:-$(git branch --show-current)}

if [[ -z "$branch" ]]; then
  echo "No branch specified and current HEAD is detached." >&2
  exit 1
fi

root=$(git rev-parse --show-toplevel)
repo=$(basename "$root")
name=$(printf '%s' "$branch" | tr / -)
worktree_root=${WORKTREE_ROOT:-"$HOME/Code/_worktrees"}
path="$worktree_root/$repo/$name"

mkdir -p "$worktree_root/$repo"

if [[ $# -eq 0 ]]; then
  git worktree add --force "$path" "$branch"
else
  git worktree add -b "$branch" "$path"
fi
