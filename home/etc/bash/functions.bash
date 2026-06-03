# Generic Bash Functions

## History Search Shorthand
function hist {
  local query="$*"

  if command -v atuin >/dev/null 2>&1; then
    if [[ -n "$query" ]]; then
      printf 'running atuin search --cmd-only --search-mode full-text -- %q | grep -- %q\n' "$query" "$query"
      atuin search --cmd-only --search-mode full-text -- "$query" | grep -- "$query"
    else
      printf 'running atuin search --cmd-only --search-mode full-text -- %q\n' "$query"
      atuin search --cmd-only --search-mode full-text -- "$query"
    fi
    return
  fi

  printf 'running history | grep -- %q\n' "$query"
  history | grep -- "$query"
}

## CD and immediately ls
function cdls {
  cd "$1" || return
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
  python3 -m http.server $1
}

function sudohttp {
  sudo python3 -m http.server "$1"
}

# Free up an HTTP port
function killport {
  kill "$(lsof -t -i "tcp:$1")"
}

# URL encode a string
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'

# Generate a UUID
alias uuid="uuidgen |  tr '[:upper:]' '[:lower:]'"
