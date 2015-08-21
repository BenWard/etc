sourceif $BREWDIR/etc/bash_completion.d/git-completion.bash
sourceif $BREWDIR/etc/bash_completion.d/git-prompt.sh

alias github="git remote -v | ruby -e 'slug = STDIN.read.split(\"\n\").collect { |line| /git@github\.com:([\w\/\.]+)/.match(line) ? \$1 : false }.select { |line| line }.first; \`open https://github.com/#{slug}\`'"
# alias git="klist -s || kinit; git"