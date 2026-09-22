# macOS Bash does not automatically source /etc/bashrc for non-login shells.
if [[ -z "${_DOTFILES_BASH_SYSTEM_LOADED:-}" ]]; then
  sourceif /etc/bashrc
  _DOTFILES_BASH_SYSTEM_LOADED=1
fi

export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=50000
export HISTFILESIZE=100000
export INPUTRC="${INPUTRC:-$HOME/.inputrc}"

shopt -s checkwinsize
shopt -s cmdhist
shopt -s histappend

bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"
bind "set colored-stats on"

_dotfiles_hist_edit() {
  local cmd
  history -s "$1"
  read -e -r -p "run: " -i "$1" cmd || return 0
  [[ -z "$cmd" ]] || eval "$cmd"
}
