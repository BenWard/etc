#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR=${1:-$(pwd)}
SOURCE_DIR=${2:-"$ROOT_DIR/home"}
STATUS=0

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"
# Validation must not trigger Homebrew auto-update or its package migrations.
export HOMEBREW_NO_AUTO_UPDATE=1

ok() {
  printf 'ok: %s\n' "$1"
}

warn() {
  printf 'warn: %s\n' "$1"
}

fail() {
  printf 'fail: %s\n' "$1"
  STATUS=1
}

require_binary() {
  local name=$1
  if command -v "$name" >/dev/null 2>&1; then
    ok "$name is available at $(command -v "$name")"
  else
    fail "$name is missing"
  fi
}

require_root_file() {
  local path=$1
  if [[ -f "$ROOT_DIR/$path" ]]; then
    ok "root file exists: $path"
  else
    fail "root file missing: $path"
  fi
}

require_source_file() {
  local path=$1
  if [[ -f "$SOURCE_DIR/$path" ]]; then
    ok "source file exists: $path"
  else
    fail "source file missing: $path"
  fi
}

require_source_dir() {
  local path=$1
  if [[ -d "$SOURCE_DIR/$path" ]]; then
    ok "source directory exists: $path"
  else
    fail "source directory missing: $path"
  fi
}

require_pattern() {
  local pattern=$1
  local path=$2
  local message=$3

  if grep -Fq "$pattern" "$SOURCE_DIR/$path"; then
    ok "$message"
  else
    fail "$message"
  fi
}

check_home_file() {
  local target=$1
  local pattern=$2

  if [[ ! -e "$target" ]]; then
    warn "$target does not exist yet; run just install or just apply"
    return
  fi

  if [[ -L "$target" ]]; then
    fail "$target is still a symlink; run just apply to replace it with a Chezmoi-managed file"
    return
  fi

  if grep -Fq "$pattern" "$target"; then
    ok "$target loads the managed shell configuration"
  else
    fail "$target does not load the managed shell configuration"
  fi
}

check_atuin_source_config() {
  if ATUIN_CONFIG_DIR="$SOURCE_DIR/dot_config/atuin" atuin config print >/dev/null; then
    ok "Atuin source config is readable"
  else
    fail "Atuin source config is readable"
  fi
}

for binary in brew just chezmoi mise starship fzf zoxide atuin bash zsh; do
  require_binary "$binary"
done

require_root_file ".chezmoiroot"
require_root_file ".gitignore"
require_root_file "tools/init.py"
require_source_file ".chezmoiignore"
require_source_file ".chezmoidata.toml"
require_source_file ".chezmoiremove"
require_source_file ".chezmoitemplates/agent-instructions.md"
require_source_file "dot_bashrc"
require_source_file "dot_bash_profile"
require_source_file "dot_gitconfig.tmpl"
require_source_dir "dot_claude"
require_source_file "dot_claude/CLAUDE.md.tmpl"
require_source_dir "dot_codex"
require_source_file "dot_codex/AGENTS.md.tmpl"
require_source_dir "dot_config/atuin"
require_source_dir "dot_config/chezmoi"
require_source_dir "dot_config/mise"
require_source_file "dot_config/chezmoi/chezmoi.example.toml"
require_source_file "dot_config/starship.toml.tmpl"
require_source_dir "dot_dotfiles_lib/bash"
require_source_dir "dot_dotfiles_lib/shell"
require_source_dir "dot_dotfiles_lib/zsh"
require_source_file "dot_zshenv"
require_source_file "dot_zprofile"
require_source_file "dot_zshrc"
require_source_dir "dot_dotfiles_lib/git-aliases"
require_source_file "dot_dotfiles_lib/git-aliases/executable_prune-local.sh"
require_source_file "dot_dotfiles_lib/git-aliases/executable_wt.sh"

require_pattern 'source "$HOME/.dotfiles_lib/bash/loader.bash"' "dot_bashrc" "dot_bashrc loads the managed shell configuration"
require_pattern 'source "$HOME/.dotfiles_lib/bash/loader.bash"' "dot_bash_profile" "dot_bash_profile loads the managed shell configuration"
require_pattern '.AGENTS.md' ".chezmoiremove" "legacy home-level agent instructions are removed"
require_pattern '{{ template "agent-instructions.md" . -}}' "dot_claude/CLAUDE.md.tmpl" "Claude includes shared agent instructions"
require_pattern '{{ template "agent-instructions.md" . -}}' "dot_codex/AGENTS.md.tmpl" "Codex includes shared agent instructions"
require_pattern '$HOME/.dotfiles_lib/git-aliases/prune-local.sh' "dot_gitconfig.tmpl" "git prune-local uses managed helper"
require_pattern '$HOME/.dotfiles_lib/git-aliases/wt.sh' "dot_gitconfig.tmpl" "git wt uses managed helper"
require_pattern 'export WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/Code/_worktrees}"' "dot_dotfiles_lib/shell/paths.sh" "default worktree root is configured"
require_pattern 'WORKTREE_ROOT:-"$HOME/Code/_worktrees"' "dot_dotfiles_lib/git-aliases/executable_wt.sh" "git wt defaults to the central worktree root"
# Runtime checks cover tool selection, ordering, and startup in both shells.
if just --justfile "$ROOT_DIR/justfile" --working-directory "$ROOT_DIR" test-shells; then
  ok "Bash/zsh startup and helper tests passed"
else
  fail "Bash/zsh startup and helper tests failed"
fi
require_pattern 'auto_sync = false' "dot_config/atuin/config.toml" "Atuin auto sync is disabled"
require_pattern '.config/chezmoi/chezmoi.toml' ".chezmoiignore" "local Chezmoi config is ignored by Chezmoi"
require_pattern 'userHostColor = "' ".chezmoidata.toml" "prompt color data is configured"
require_pattern '[data]' "dot_config/chezmoi/chezmoi.example.toml" "Chezmoi local data example is configured"
require_pattern 'userHostColor = "green"' "dot_config/chezmoi/chezmoi.example.toml" "Haemogloben prompt color example is green"
check_atuin_source_config

check_home_file "$HOME/.bashrc" 'source "$HOME/.dotfiles_lib/bash/loader.bash"'
check_home_file "$HOME/.bash_profile" 'source "$HOME/.dotfiles_lib/bash/loader.bash"'
check_home_file "$HOME/.zshenv" 'source "$HOME/.dotfiles_lib/shell/env.sh"'
check_home_file "$HOME/.zprofile" 'source "$HOME/.dotfiles_lib/shell/env.sh"'
check_home_file "$HOME/.zshrc" 'source "$HOME/.dotfiles_lib/zsh/loader.zsh"'


if command -v brew >/dev/null 2>&1; then
  for formula in bash-completion@2 bash-preexec; do
    if brew list --formula "$formula" >/dev/null 2>&1; then
      ok "$formula is installed"
    else
      fail "$formula is not installed"
    fi
  done

  if brew bundle check --file "$ROOT_DIR/Brewfile" --verbose; then
    ok "Brewfile is satisfied"
  else
    fail "Brewfile is not satisfied"
  fi
fi

if command -v chezmoi >/dev/null 2>&1; then
  if chezmoi --source "$ROOT_DIR" managed >/dev/null 2>&1; then
    ok "Chezmoi can read the source state"
  else
    fail "Chezmoi cannot read the source state"
  fi

  if chezmoi --source "$ROOT_DIR" doctor; then
    ok "chezmoi doctor passed"
  else
    fail "chezmoi doctor reported problems"
  fi
fi

exit "$STATUS"
