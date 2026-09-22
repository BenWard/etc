if [[ -n "${BREWDIR:-}" && -d "$BREWDIR/share/zsh/site-functions" ]]; then
  fpath=("$BREWDIR/share/zsh/site-functions" "${fpath[@]}")
fi
if [[ -d "$HOME/.orbstack/shell/completions/zsh" ]]; then
  fpath=("$HOME/.orbstack/shell/completions/zsh" "${fpath[@]}")
fi
typeset -U fpath
autoload -Uz compinit
# Ignore insecure completion directories without prompting or trusting them.
compinit -i
if command -v npm >/dev/null 2>&1; then
  eval "$(npm completion 2>/dev/null)"
fi
