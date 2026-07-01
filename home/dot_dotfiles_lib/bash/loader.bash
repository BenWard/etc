DOTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source a file if it exists.
function sourceif {
  [[ -e "$1" ]] && source "$1"
}

# Reload this profile.
function resource {
  source ~/.bashrc
}

source "$DOTPATH/paths.bash"

source "$DOTPATH/node.bash"
source "$DOTPATH/python.bash"
source "$DOTPATH/ruby.bash"
source "$DOTPATH/scala.bash"

# If interactive
if [ -n "$PS1" ]; then
  source "$DOTPATH/terminal.bash"
  source "$DOTPATH/completions.bash"
  source "$DOTPATH/functions.bash"
  source "$DOTPATH/shell.bash"

  source "$DOTPATH/applications.bash"
  source "$DOTPATH/docker.bash"
  source "$DOTPATH/git.bash"

  if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  fi

  if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
  fi

  if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
  else
    PS1='[\A] \u@\h \w\$ '
  fi

  if [[ -n "${BREWDIR:-}" ]]; then
    sourceif "$BREWDIR/etc/profile.d/bash-preexec.sh"
  fi

  if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash)"
  fi

fi

sourceif ~/.extras.bash
