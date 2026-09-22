# Guards belong to this shell process, never the exported environment.
if [[ -z "${_DOTFILES_COMPLETIONS_LOADED:-}" ]]; then
  source "$HOME/.dotfiles_lib/$DOTFILES_SHELL/completions.$DOTFILES_SHELL"
  _DOTFILES_COMPLETIONS_LOADED=1
fi

if [[ -z "${_DOTFILES_OPAM_LOADED:-}" ]]; then
  if [[ -r "$HOME/.opam/opam-init/init.$DOTFILES_SHELL" ]]; then
    source "$HOME/.opam/opam-init/init.$DOTFILES_SHELL" >/dev/null 2>&1
  else
    sourceif "$HOME/.opam/opam-init/init.sh" >/dev/null 2>&1
  fi
  _DOTFILES_OPAM_LOADED=1
fi

if command -v mise >/dev/null 2>&1; then
  if [[ -z "${_DOTFILES_MISE_LOADED:-}" ]]; then
    eval "$(mise activate "$DOTFILES_SHELL")"
    _DOTFILES_MISE_LOADED=1
  else
    # PATH was refreshed during reload; restore active project tool paths.
    eval "$(mise hook-env --shell "$DOTFILES_SHELL" --force)"
  fi
fi
# fzf restores ZLE options which cannot be changed without terminal input.
if [[ -t 0 && -z "${_DOTFILES_FZF_LOADED:-}" ]] && command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --"$DOTFILES_SHELL")"
  _DOTFILES_FZF_LOADED=1
fi
if [[ -z "${_DOTFILES_ZOXIDE_LOADED:-}" ]] && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init "$DOTFILES_SHELL")"
  _DOTFILES_ZOXIDE_LOADED=1
fi
if [[ -z "${_DOTFILES_STARSHIP_LOADED:-}" ]]; then
  if command -v starship >/dev/null 2>&1; then
    eval "$(starship init "$DOTFILES_SHELL")"
    _DOTFILES_STARSHIP_LOADED=1
  elif [[ "$DOTFILES_SHELL" = bash ]]; then
    PS1='[\A] \u@\h \w\$ '
  else
    PS1='[%D{%H:%M}] %n@%m %~%# '
  fi
fi
if [[ "$DOTFILES_SHELL" = bash && -z "${_DOTFILES_PREEXEC_LOADED:-}" && -n "${BREWDIR:-}" ]]; then
  if [[ -r "$BREWDIR/etc/profile.d/bash-preexec.sh" ]]; then
    source "$BREWDIR/etc/profile.d/bash-preexec.sh"
    _DOTFILES_PREEXEC_LOADED=1
  fi
fi
# Atuin's Enter-to-execute mode reads terminal settings during initialization.
# Developer tools also launch interactive (-i) shells with piped stdin.
if [[ -t 0 && -z "${_DOTFILES_ATUIN_LOADED:-}" ]] && command -v atuin >/dev/null 2>&1; then
  if [[ "$DOTFILES_SHELL" = zsh || -n "${_DOTFILES_PREEXEC_LOADED:-}" ]]; then
    eval "$(atuin init "$DOTFILES_SHELL")"
    _DOTFILES_ATUIN_LOADED=1
  fi
fi
if [[ -z "${_DOTFILES_THEFUCK_LOADED:-}" ]] && command -v thefuck >/dev/null 2>&1; then
  # Existing Bash sessions may still have the former alias named f.
  unalias f 2>/dev/null || true
  eval "$(TF_SHELL="$DOTFILES_SHELL" thefuck --alias f)"
  _DOTFILES_THEFUCK_LOADED=1
fi
