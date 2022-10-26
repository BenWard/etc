# Paths

# Home
export PATH=$HOME/bin:$PATH

## Homebrew

if [[ -x "$(command -v brew)" ]]; then
  export BREWDIR=`brew --prefix`
fi

export PATH=$BREWDIR/bin:$BREWDIR/sbin:$PATH
export PATH=/usr/local/bin:/usr/local/sbin:$PATH

## PHP
export PATH="/usr/local/opt/php@7.4/bin:$PATH"

## MySQL
export PATH=$BREWDIR/mysql/bin:$PATH

## OPAM
test -r $HOME/.opam/opam-init/init.sh && . $HOME/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true
