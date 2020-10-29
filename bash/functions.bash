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
