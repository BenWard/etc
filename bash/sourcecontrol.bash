# Source Control Functions

## cvs

function cvstatus {
  cvs status 2>/dev/null | grep Status: | grep -v "to-date"
}

## bzr

### Bazaar Diff in FileMerge
function bzrdiff {
if [ $# -lt 1 ]
then
cat <<-END
        Usage: bzrdiff file
        Will automatically compare file.OTHER and file.THIS
END
else
  opendiff $1.OTHER $1.THIS -ancestor $1.BASE
fi
}

## Git
source /usr/local/etc/bash_completion.d/git-completion.bash
source /usr/local/etc/bash_completion.d/git-prompt.sh

alias github="git remote -v | ruby -e 'slug = STDIN.read.split(\"\n\").collect { |line| /git@github\.com:([\w\/\.]+)/.match(line) ? \$1 : false }.select { |line| line }.first; \`open https://github.com/#{slug}\`'"