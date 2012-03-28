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
alias github="open \`git remote -v | ruby -e 'remote = STDIN.read.split(\"\n\").select { |line| line =~ /git@github/ }.first.split(\"\t\")[1].split(\":\")[1].each { |slug| puts \"https://github.com/#{slug.split(\" \").first}\" }'\`"