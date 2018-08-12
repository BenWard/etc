# Generic Bash Functions

## Enable autojump: https://github.com/joelthelion/autojump
if [ -f `brew --prefix`/etc/autojump ]; then
  . `brew --prefix`/etc/autojump
fi

## History Search Shorthand
function hist {
    history | grep $1
}

## Sourcing this file
function sourceif {
  [[ -e $1 ]] && source $1
}

function resource {
  source ~/.bash_profile
}

## CD and immediately ls
function cdls {
  cd $1
  ls
}

## SSH Auth
alias sshadd='ssh-add ~/.ssh/id_rsa'

## Guess what I meant
alias f='$(thefuck $(fc -ln -1))'

# VirtualBox management
alias vb=VBoxManage

# Handy Python web-servers: Usage `serve [port]`
function http {
  python -m SimpleHTTPServer $1
}

function sudohttp {
  sudo python -m SimpleHTTPServer $1
}

# Free up an HTTP port
function killport {
  kill `lsof -t -i tcp:$1`
}

# URL encode a string
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1])"'

# Open Sublime Project
function subl {
  if [ -n "$1" ]; then
    command subl $1
  elif [ -f *.sublime-project ]; then
    command subl *.sublime-project
  else
    command subl .
  fi
}
# Open vscode directory
function code {
  if [ -n "$1" ]; then
    command code $1
  else
    command subl .
  fi
}
