# Mac
sourceif $BREWDIR/etc/bash_completion.d/git-completion.bash
sourceif $BREWDIR/etc/bash_completion.d/git-prompt.sh

# CentOS
sourceif /usr/share/git-core/contrib/completion/git-prompt.sh

alias github="git remote -v | ruby -e 'slug = STDIN.read.split(\"\n\").collect { |line| /git@github\.com:([\w\/\.\-_]+)/.match(line) ? \$1 : false }.select { |line| line }.first; \`open https://github.com/#{slug}\`'"

gitroot() {
  local root="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [ -z "$root" ]; then
    echo "Not a git repository" >&2
    return 1
  fi
  cd "$root/$1"
}
