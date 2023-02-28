# Paths

# Home
export PATH=$HOME/bin:$PATH

## Homebrew
export PATH=/opt/homebrew/bin:$PATH

if [[ -x "$(command -v brew)" ]]; then
  export BREWDIR=`brew --prefix`
fi

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$BREWDIR/bin:$BREWDIR/sbin:$PATH

## PHP
export PATH=$BREWDIR/opt/php@7.4/bin:$PATH

## MySQL
export PATH=$BREWDIR/mysql/bin:$PATH

## OPAM
test -r $HOME/.opam/opam-init/init.sh && . $HOME/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true
