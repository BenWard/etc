# Paths

# Home
export PATH="$HOME/bin:$PATH"
export WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/Code/_worktrees}"

if [[ -d "$HOME/.orbstack/bin" ]]; then
  export PATH="$HOME/.orbstack/bin:$PATH"
fi

## Homebrew
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

if command -v brew >/dev/null 2>&1; then
  export BREWDIR
  BREWDIR="$(brew --prefix)"
fi

if [[ -n "${BREWDIR:-}" ]]; then
  export PATH="$BREWDIR/bin:$BREWDIR/sbin:$PATH"

  ## MySQL
  export PATH="$BREWDIR/opt/mysql/bin:$PATH"
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

## OPAM
test -r "$HOME/.opam/opam-init/init.sh" && . "$HOME/.opam/opam-init/init.sh" > /dev/null 2> /dev/null || true

export PATH="$HOME/.local/bin:$PATH"
