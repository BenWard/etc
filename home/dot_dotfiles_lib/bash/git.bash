# Mac
if [[ -n "${BREWDIR:-}" ]]; then
  sourceif "$BREWDIR/etc/bash_completion.d/git-completion.bash"
fi

# CentOS
sourceif "/usr/share/git-core/contrib/completion/git-completion.bash"

_github_remote_to_web_url() {
  local remote=$1
  local slug

  case "$remote" in
    git@github.com:*)
      slug=${remote#git@github.com:}
      ;;
    https://github.com/*)
      slug=${remote#https://github.com/}
      ;;
    http://github.com/*)
      slug=${remote#http://github.com/}
      ;;
    ssh://git@github.com/*)
      slug=${remote#ssh://git@github.com/}
      ;;
    ssh://github.com/*)
      slug=${remote#ssh://github.com/}
      ;;
    git://github.com/*)
      slug=${remote#git://github.com/}
      ;;
    *)
      return 1
      ;;
  esac

  slug=${slug%.git}
  slug=${slug%/}
  printf 'https://github.com/%s\n' "$slug"
}

_github_open_url() {
  local url=$1

  if command -v open >/dev/null 2>&1; then
    open "$url"
  else
    printf '%s\n' "$url"
  fi
}

github() {
  local remote url

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not a git repository" >&2
    return 1
  fi

  remote=$(git config --get remote.origin.url 2>/dev/null || true)
  if [[ -n "$remote" ]]; then
    if url=$(_github_remote_to_web_url "$remote"); then
      _github_open_url "$url"
      return
    fi
  fi

  while read -r remote_name remote_url remote_type; do
    [[ "$remote_type" != "(fetch)" ]] && continue

    if url=$(_github_remote_to_web_url "$remote_url"); then
      _github_open_url "$url"
      return
    fi
  done < <(git remote -v)

  echo "No GitHub remote found" >&2
  return 1
}

# Create (or reuse) a git worktree and cd into it. A git alias can't change the
# calling shell's directory, so the cd has to happen in this function.
wt() {
  local dir
  dir=$(git wt "$@") || return
  [[ -n "$dir" ]] && cd "$dir"
}

gitroot() {
  local root="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [ -z "$root" ]; then
    echo "Not a git repository" >&2
    return 1
  fi
  cd "$root/$1"
}
