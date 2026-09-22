HISTFILE=${HISTFILE:-${ZDOTDIR:-$HOME}/.zsh_history}
HISTSIZE=50000
SAVEHIST=100000
setopt APPEND_HISTORY EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE

# Run before fzf/Atuin so those integrations retain their key bindings.
if [[ -z "${_DOTFILES_ZSH_KEYS_LOADED:-}" ]]; then
  bindkey -e
  _DOTFILES_ZSH_KEYS_LOADED=1
fi
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

_dotfiles_hist_edit() {
  # Push onto ZLE's input stack; the next prompt allows editing before Enter.
  print -rz -- "$1"
}
