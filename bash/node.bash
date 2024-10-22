# nvm

# If interactive
if [ -n "$PS1" ]; then
  sourceif "$BREWDIR/nvm/nvm.sh"
  sourceif "$NVM_DIR/bash_completion"
fi

alias nr='npm run $1'

# Enable Node@10
# export PATH=$BREWDIR/opt/node@10/bin:$PATH;

# Enable Node@16
# export PATH=$BREWDIR/opt/node@16/bin:$PATH;
