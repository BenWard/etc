# nvm

# If interactive
if [ -n "$PS1" ]; then
  sourceif "$BREWDIR/nvm/nvm.sh"
  sourceif "$NVM_DIR/bash_completion"
fi

alias nr='npm run $1'

# Enable Node@10
export PATH="/usr/local/opt/node@10/bin:$PATH";
