# Generic Bash Functions

## Enable autojump: https://github.com/joelthelion/autojump
if [ -f $BREWDIR/etc/autojump ]; then
  . $BREWDIR/etc/autojump
fi

## History Search Shorthand
function hist {
  history | grep $1
}

## CD and immediately ls
function cdls {
  cd $1
  ls
}

## SSH Auth
alias sshadd='ssh-add ~/.ssh/id_rsa'

## Guess what I meant
if [[ -x "$(command -v thefuck)" ]]; then
  alias f='$(thefuck $(fc -ln -1))'
fi

# VirtualBox management
if [[ -x "$(command -v VBoxManage)" ]]; then
  alias vb=VBoxManage
fi

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
if [[ -x "$(command -v subl)" ]]; then
  function subl {
    if [ -n "$1" ]; then
      command subl $1
    elif [ -f *.sublime-project ]; then
      command subl *.sublime-project
    else
      command subl .
    fi
  }
fi

# Open vscode directory
if [[ -x "$(command -v code)" ]]; then
  function code {
    if [ -n "$1" ]; then
      command code $1
    else
      command code .
    fi
  }
fi
