# Shared Bash/zsh syntax; this is not a POSIX sh startup file.
if [[ -n "${ZSH_VERSION:-}" ]]; then
  DOTFILES_SHELL=zsh
elif [[ -n "${BASH_VERSION:-}" ]]; then
  DOTFILES_SHELL=bash
else
  return 1
fi
DOTPATH="$HOME/.dotfiles_lib/shell"

sourceif() {
  if [[ -r "$1" ]]; then
    source "$1"
  fi
}

resource() {
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshrc"
  else
    source "$HOME/.bashrc"
  fi
}

source "$DOTPATH/env.sh"
source "$DOTPATH/node.sh"
source "$DOTPATH/python.sh"
source "$DOTPATH/ruby.sh"
source "$DOTPATH/scala.sh"

case $- in
  *i*)
    source "$DOTPATH/terminal.sh"
    source "$DOTPATH/shell.sh"
    source "$HOME/.dotfiles_lib/$DOTFILES_SHELL/shell.$DOTFILES_SHELL"
    source "$DOTPATH/functions.sh"
    source "$DOTPATH/applications.sh"
    source "$DOTPATH/docker.sh"
    source "$DOTPATH/git.sh"
    source "$DOTPATH/integrations.sh"
    ;;
esac

sourceif "$HOME/.extras.sh"
sourceif "$HOME/.extras.$DOTFILES_SHELL"
