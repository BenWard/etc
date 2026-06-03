if [[ -n "${BREWDIR:-}" ]] && [[ -f "$BREWDIR/etc/profile.d/bash_completion.sh" ]]; then
  source "$BREWDIR/etc/profile.d/bash_completion.sh"
fi

if [[ -n "${BREWDIR:-}" ]] && [[ -f "$BREWDIR/etc/bash_completion.d/npm" ]]; then
  source "$BREWDIR/etc/bash_completion.d/npm"
elif command -v npm >/dev/null 2>&1; then
  eval "$(npm completion 2>/dev/null)"
fi
