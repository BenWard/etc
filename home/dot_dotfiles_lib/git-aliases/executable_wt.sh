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

# Print the path of the worktree already checked out for $branch, if any.
worktree_for_branch() {
  local target="refs/heads/$1" wt=""
  while IFS= read -r line; do
    case "$line" in
      worktree\ *) wt=${line#worktree } ;;
      branch\ *) [[ "${line#branch }" == "$target" ]] && { printf '%s\n' "$wt"; return 0; } ;;
    esac
  done < <(git worktree list --porcelain)
  return 1
}

mkdir -p "$worktree_root/$repo"

if existing=$(worktree_for_branch "$branch"); then
  # A worktree already holds this branch; reuse it rather than erroring.
  echo "Branch '$branch' already checked out at $existing" >&2
  path=$existing
elif git show-ref --verify --quiet "refs/heads/$branch"; then
  # Branch exists but isn't checked out anywhere; link a new worktree to it.
  git worktree add "$path" "$branch" >&2
else
  # New branch.
  git worktree add -b "$branch" "$path" >&2
fi || exit 1

# Emit the worktree path on stdout so the shell wrapper can cd into it.
printf '%s\n' "$path"
