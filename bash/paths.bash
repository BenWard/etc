# Paths

# Home
export PATH=$HOME/bin:$PATH

## Homebrew

if [[ -f `which brew` ]]; then
  export BREWDIR=`brew --prefix`
fi


export PATH=$BREWDIR/bin:$BREWDIR/sbin:$PATH
export PATH=/usr/local/bin:/usr/local/sbin:$PATH

## MySQL
export PATH=$BREWDIR/mysql/bin:$PATH

