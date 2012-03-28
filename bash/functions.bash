# Generic Bash Functions

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