#!/usr/bin/env bash

set -u

status=0

while IFS= read -r branch; do
  path=$(
    git worktree list --porcelain |
      awk -v ref="refs/heads/$branch" '
        /^worktree / { path = substr($0, 10) }
        /^branch / && $2 == ref { print path; exit }
      '
  )

  if [[ -n "$path" ]]; then
    if ! git worktree remove "$path"; then
      status=1
      continue
    fi
  fi

  if ! git branch -D "$branch"; then
    status=1
  fi
done < <(
  git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads |
    awk '$2 == "[gone]" { print $1 }'
)

exit "$status"
