export CHROME_BIN='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

if command -v VBoxManage >/dev/null 2>&1; then
  alias vb=VBoxManage
fi

if command -v subl >/dev/null 2>&1; then
  subl() {
    if [[ $# -gt 0 ]]; then
      command subl "$@"
    else
      local file
      local -a projects
      projects=()
      # Avoid shell-specific nullglob behavior; preserve spaces and newlines.
      while IFS= read -r -d '' file; do
        projects+=("$file")
      done < <(find . ! -name . -prune -type f -name '*.sublime-project' -print0)
      if [[ ${#projects[@]} -gt 0 ]]; then
        command subl "${projects[@]}"
      else
        command subl .
      fi
    fi
  }
fi

if command -v code >/dev/null 2>&1; then
  code() {
    [[ $# -gt 0 ]] || set -- .
    command code "$@"
  }
fi

if command -v nova >/dev/null 2>&1; then
  nova() {
    [[ $# -gt 0 ]] || set -- .
    command nova open "$@" --no-wait
  }
fi
