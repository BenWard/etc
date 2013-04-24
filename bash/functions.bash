# Generic Bash Functions

## Enable autojump: https://github.com/joelthelion/autojump
if [ -f `brew --prefix`/etc/autojump ]; then
  . `brew --prefix`/etc/autojump
fi

## History Search Shorthand
function hist {
    history | grep $1
}

## Re-source this file
function resource {
  source ~/.bash_profile
}

## CD and immediately ls
function cdls {
  cd $1
  ls
}

# URL encode a string
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1])"'

alias fuj='~/Code/fuj/lib/fuj.rb'
alias jira=fuj