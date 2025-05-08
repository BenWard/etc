# nvm

# If interactive
if [ -n "$PS1" ]; then
  sourceif "$BREWDIR/nvm/nvm.sh"
  sourceif "$NVM_DIR/bash_completion"
fi

alias nr='npm run $1'

# Enable Node@20
export PATH=$BREWDIR/opt/node@20/bin:$PATH;
