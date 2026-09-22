# Shared Bash/zsh functions

## History Search Shorthand
##
## - `hist` (no args): opens atuin's interactive TUI picker.
## - `hist <query>`: pipes matching commands through fzf; the chosen line is
##   prefilled on an editable prompt — Enter to run, edit first if you like.
## - Falls back to `history | grep` if atuin is missing, or to a bare list if
##   fzf is missing.
function hist {
  local query="$*"

  if ! command -v atuin >/dev/null 2>&1; then
    history | grep -- "$query"
    return
  fi

  if [[ -z "$query" ]]; then
    atuin search -i
    return
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    atuin search --cmd-only --search-mode full-text -- "$query"
    return
  fi

  local choice
  choice=$(atuin search --cmd-only --search-mode full-text -- "$query" \
           | awk '!seen[$0]++' \
           | fzf --height 40% --reverse --no-sort --tac --query "$query" --prompt 'hist> ') || return 0
  [[ -z "$choice" ]] && return 0

  _dotfiles_hist_edit "$choice"
}

## CD and immediately ls
function cdls {
  cd "${1:-$HOME}" || return
  ls
}

function lsl {
  ls -lh
}

function lsa {
  ls -alh
}

## SSH Auth
alias sshadd='ssh-add ~/.ssh/id_rsa'

# Handy Python web-servers: Usage `serve [port]`
function http {
  python3 -m http.server "$@"
}

function sudohttp {
  sudo python3 -m http.server "$@"
}

# Free up an HTTP port
function killport {
  if [[ -z "${1:-}" ]]; then
    printf 'Usage: killport PORT\n' >&2
    return 1
  fi
  local pid
  local -a pids
  pids=()
  while IFS= read -r pid; do
    [[ -n "$pid" ]] && pids+=("$pid")
  done < <(lsof -t -i "tcp:$1")
  [[ ${#pids[@]} -gt 0 ]] || return 0
  kill "${pids[@]}"
}

# URL encode a string
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'

# Generate a UUID
alias uuid="uuidgen |  tr '[:upper:]' '[:lower:]'"
