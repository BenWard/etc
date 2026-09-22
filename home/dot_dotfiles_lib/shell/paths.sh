# Shared by both shells, including non-interactive zsh. No subprocesses here.
# Move managed entries to the front without duplicating them; retain the
# relative order (and any intentional empty entries) of the inherited PATH.
_dotfiles_prepend_path() {
  local entry rest=${PATH-} result=$1
  while [[ -n "$rest" ]]; do
    entry=${rest%%:*}
    [[ "$entry" = "$1" ]] || result="$result:$entry"
    case "$rest" in
      *:) rest=${rest#*:}; [[ -n "$rest" ]] || result="$result:" ;;
      *:*) rest=${rest#*:} ;;
      *) break ;;
    esac
  done
  export PATH="$result"
}

_dotfiles_prepend_path "$HOME/bin"
if [[ -d "$HOME/.orbstack/bin" ]]; then
  _dotfiles_prepend_path "$HOME/.orbstack/bin"
fi

# Respect a supplied custom prefix. Prefer native Homebrew on Apple Silicon.
if [[ -z "${BREWDIR:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREWDIR=/opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then
    BREWDIR=/usr/local
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    BREWDIR=/home/linuxbrew/.linuxbrew
  fi
fi
export BREWDIR
_dotfiles_prepend_path /opt/homebrew/sbin
_dotfiles_prepend_path /opt/homebrew/bin
_dotfiles_prepend_path /usr/local/sbin
_dotfiles_prepend_path /usr/local/bin
if [[ -n "${BREWDIR:-}" ]]; then
  _dotfiles_prepend_path "$BREWDIR/sbin"
  _dotfiles_prepend_path "$BREWDIR/bin"
  _dotfiles_prepend_path "$BREWDIR/opt/mysql/bin"
fi
_dotfiles_prepend_path "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
_dotfiles_prepend_path "$HOME/.local/bin"
export WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/Code/_worktrees}"
