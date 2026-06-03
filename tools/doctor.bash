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

for binary in brew just chezmoi mise starship fzf zoxide atuin bash; do
  require_binary "$binary"
done

require_root_file ".chezmoiroot"
require_source_file ".chezmoidata.toml"
require_source_file "dot_bashrc"
require_source_file "dot_bash_profile"
require_source_file "dot_gitconfig"
require_source_file "dot_AGENTS.md"
require_source_dir "dot_claude"
require_source_dir "dot_codex"
require_source_dir "dot_config/atuin"
require_source_dir "dot_config/mise"
require_source_file "dot_config/starship.toml.tmpl"
require_source_dir "etc/bash"
require_source_dir "etc/git-aliases"

require_pattern 'source "$HOME/etc/bash/loader.bash"' "dot_bashrc" "dot_bashrc loads the managed bash loader"
require_pattern 'source "$HOME/etc/bash/loader.bash"' "dot_bash_profile" "dot_bash_profile loads the managed bash loader"
require_pattern 'mise activate bash' "etc/bash/paths.bash" "mise activation is configured"
require_pattern 'fzf --bash' "etc/bash/loader.bash" "fzf bash integration is configured"
require_pattern 'zoxide init bash' "etc/bash/loader.bash" "zoxide bash integration is configured"
require_pattern 'atuin init bash' "etc/bash/loader.bash" "Atuin bash integration is configured"
require_pattern 'starship init bash' "etc/bash/loader.bash" "Starship prompt integration is configured"
require_pattern_order 'starship init bash' 'atuin init bash' "etc/bash/loader.bash" "Starship initializes before Atuin"
require_pattern 'bash_completion.d/npm' "etc/bash/completions.bash" "npm completion is explicitly configured"
require_pattern 'auto_sync = false' "dot_config/atuin/config.toml" "Atuin auto sync is disabled"
require_pattern 'userHostColor = "purple"' ".chezmoidata.toml" "prompt color data is configured"

check_home_file "$HOME/.bashrc" 'source "$HOME/etc/bash/loader.bash"'
check_home_file "$HOME/.bash_profile" 'source "$HOME/etc/bash/loader.bash"'

if command -v brew >/dev/null 2>&1; then
  if brew list --formula bash-completion@2 >/dev/null 2>&1; then
    ok "bash-completion@2 is installed"
  else
    fail "bash-completion@2 is not installed"
  fi

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
