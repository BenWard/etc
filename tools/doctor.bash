#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR=${1:-$(pwd)}
SOURCE_DIR=${2:-"$ROOT_DIR/home"}
STATUS=0

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

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

require_pattern_order() {
  local first_pattern=$1
  local second_pattern=$2
  local path=$3
  local message=$4
  local first_line second_line

  first_line=$(grep -n -F "$first_pattern" "$SOURCE_DIR/$path" | head -n 1 | cut -d: -f1)
  second_line=$(grep -n -F "$second_pattern" "$SOURCE_DIR/$path" | head -n 1 | cut -d: -f1)

  if [[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]]; then
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
    ok "$target loads the managed bash loader"
  else
    fail "$target does not load the managed bash loader"
  fi
}

check_atuin_source_config() {
  if ATUIN_CONFIG_DIR="$SOURCE_DIR/dot_config/atuin" atuin config print >/dev/null; then
    ok "Atuin source config is readable"
  else
    fail "Atuin source config is readable"
  fi
}

for binary in brew just chezmoi mise starship fzf zoxide atuin bash; do
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
require_source_dir "dot_dotfiles_lib/git-aliases"
require_source_file "dot_dotfiles_lib/git-aliases/executable_prune-local.sh"
require_source_file "dot_dotfiles_lib/git-aliases/executable_wt.sh"

require_pattern 'source "$HOME/.dotfiles_lib/bash/loader.bash"' "dot_bashrc" "dot_bashrc loads the managed bash loader"
require_pattern 'source "$HOME/.dotfiles_lib/bash/loader.bash"' "dot_bash_profile" "dot_bash_profile loads the managed bash loader"
require_pattern '.AGENTS.md' ".chezmoiremove" "legacy home-level agent instructions are removed"
require_pattern '{{ template "agent-instructions.md" . -}}' "dot_claude/CLAUDE.md.tmpl" "Claude includes shared agent instructions"
require_pattern '{{ template "agent-instructions.md" . -}}' "dot_codex/AGENTS.md.tmpl" "Codex includes shared agent instructions"
require_pattern '$HOME/.dotfiles_lib/git-aliases/prune-local.sh' "dot_gitconfig.tmpl" "git prune-local uses managed helper"
require_pattern '$HOME/.dotfiles_lib/git-aliases/wt.sh' "dot_gitconfig.tmpl" "git wt uses managed helper"
require_pattern 'export WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/Code/_worktrees}"' "dot_dotfiles_lib/bash/paths.bash" "default worktree root is configured"
require_pattern 'WORKTREE_ROOT:-"$HOME/Code/_worktrees"' "dot_dotfiles_lib/git-aliases/executable_wt.sh" "git wt defaults to the central worktree root"
require_pattern 'mise activate bash' "dot_dotfiles_lib/bash/paths.bash" "mise activation is configured"
require_pattern 'fzf --bash' "dot_dotfiles_lib/bash/loader.bash" "fzf bash integration is configured"
require_pattern 'zoxide init bash' "dot_dotfiles_lib/bash/loader.bash" "zoxide bash integration is configured"
require_pattern 'bash-preexec.sh' "dot_dotfiles_lib/bash/loader.bash" "bash-preexec integration is configured"
require_pattern 'atuin init bash' "dot_dotfiles_lib/bash/loader.bash" "Atuin bash integration is configured"
require_pattern 'starship init bash' "dot_dotfiles_lib/bash/loader.bash" "Starship prompt integration is configured"
require_pattern_order 'starship init bash' 'atuin init bash' "dot_dotfiles_lib/bash/loader.bash" "Starship initializes before Atuin"
require_pattern_order 'bash-preexec.sh' 'atuin init bash' "dot_dotfiles_lib/bash/loader.bash" "bash-preexec loads before Atuin"
require_pattern 'bash_completion.d/npm' "dot_dotfiles_lib/bash/completions.bash" "npm completion is explicitly configured"
require_pattern 'auto_sync = false' "dot_config/atuin/config.toml" "Atuin auto sync is disabled"
require_pattern '.config/chezmoi/chezmoi.toml' ".chezmoiignore" "local Chezmoi config is ignored by Chezmoi"
require_pattern 'userHostColor = "' ".chezmoidata.toml" "prompt color data is configured"
require_pattern '[data]' "dot_config/chezmoi/chezmoi.example.toml" "Chezmoi local data example is configured"
require_pattern 'userHostColor = "green"' "dot_config/chezmoi/chezmoi.example.toml" "Haemogloben prompt color example is green"
check_atuin_source_config

check_home_file "$HOME/.bashrc" 'source "$HOME/.dotfiles_lib/bash/loader.bash"'
check_home_file "$HOME/.bash_profile" 'source "$HOME/.dotfiles_lib/bash/loader.bash"'

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
