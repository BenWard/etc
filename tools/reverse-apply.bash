#!/usr/bin/env bash

# Reverse-apply: pull local $HOME changes back into the Chezmoi source state,
# choosing which hunks to keep the same way `git add -p` works.
#
# Flow:
#   1. `chezmoi re-add` copies modified target files into the source working
#      tree (templates, encrypted files, and non-files are left untouched).
#   2. `git add -p` lets you stage the hunks you want with y/n/a/d prompts.
#   3. Unstaged (rejected) hunks are reverted, leaving only the accepted
#      changes in the source, ready to review, commit, and push.
#
# Run this before `just apply` so local edits are captured instead of clobbered.

set -uo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

ROOT_DIR=${1:-$(pwd)}
shift || true
# Remaining args are optional target paths passed through to `chezmoi re-add`
# and used to scope `git add -p` (e.g. reverse-apply just ~/.bashrc).
TARGETS=("$@")

# Chezmoi's source-state root, per .chezmoiroot.
SOURCE_SUBDIR="home"
SOURCE_TREE="$ROOT_DIR/$SOURCE_SUBDIR"

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

command -v chezmoi >/dev/null 2>&1 || die "chezmoi is not installed"
command -v git >/dev/null 2>&1 || die "git is not installed"
[[ -d "$ROOT_DIR/.git" ]] || die "$ROOT_DIR is not a git repository"
[[ -d "$SOURCE_TREE" ]] || die "source tree missing: $SOURCE_TREE"

git_repo() {
  git -C "$ROOT_DIR" "$@"
}

# The reject step discards unstaged changes under the source tree, so require a
# clean starting point: unrelated uncommitted work would be lost otherwise.
if [[ -n "$(git_repo status --porcelain -- "$SOURCE_SUBDIR")" ]]; then
  die "source tree has uncommitted changes; commit or stash them first"
fi

# Snapshot which targets Chezmoi considers modified so we can report anything
# re-add cannot capture (templates, encrypted files) once it has run.
targets_modified_before() {
  chezmoi --source "$ROOT_DIR" status ${TARGETS[@]+"${TARGETS[@]}"} 2>/dev/null \
    | awk '$0 ~ /^.M/ { print substr($0, 4) }'
}

BEFORE=$(targets_modified_before)
if [[ -z "$BEFORE" ]]; then
  printf 'No local changes to pull into the source state.\n'
  exit 0
fi

printf 'Pulling local changes into the source state...\n'
chezmoi --source "$ROOT_DIR" re-add ${TARGETS[@]+"${TARGETS[@]}"} \
  || die "chezmoi re-add failed"

# Anything still modified in the target after re-add could not be captured.
AFTER=$(targets_modified_before)
if [[ -n "$AFTER" ]]; then
  printf '\nSkipped (templates/encrypted cannot be reverse-applied automatically):\n'
  printf '  %s\n' $AFTER
  printf 'Edit these source files by hand if you want to keep those changes.\n'
fi

if [[ -z "$(git_repo status --porcelain -- "$SOURCE_SUBDIR")" ]]; then
  printf '\nNothing to stage; source already matches the captured files.\n'
  exit 0
fi

printf '\nChoose the changes to keep (git add -p: [y]es/[n]o/[a]ll/[d]o not this file):\n\n'
git_repo add -p -- "$SOURCE_SUBDIR"

if git_repo diff --cached --quiet -- "$SOURCE_SUBDIR"; then
  # Nothing was staged: revert re-add entirely, leaving the source untouched.
  git_repo restore --worktree -- "$SOURCE_SUBDIR"
  printf '\nNo hunks selected; source state left unchanged.\n'
  exit 0
fi

# Drop the rejected (unstaged) hunks, keeping only the staged changes.
git_repo restore --worktree -- "$SOURCE_SUBDIR"

printf '\nCaptured. Staged changes:\n'
git_repo diff --cached --stat -- "$SOURCE_SUBDIR"
printf '\nReview with `git diff --staged`, then commit and push.\n'
printf 'Run `just apply` afterwards to re-sync $HOME with the source state.\n'
