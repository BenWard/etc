DOTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## source a file if it exists
function sourceif {
  [[ -e $1 ]] && source $1
}

## reload this profile
function resource {
  source ~/.bashrc
}

source $DOTPATH/machine.bash
source $DOTPATH/paths.bash

source $DOTPATH/node.bash
source $DOTPATH/ruby.bash
source $DOTPATH/scala.bash

# If interactive
if [ -n "$PS1" ]; then
  # Use https://github.com/mrzool/bash-sensible as a base:
  source $DOTPATH/sensible/sensible.bash

  source $DOTPATH/terminal.bash
  source $DOTPATH/completions.bash
  source $DOTPATH/functions.bash
  source $DOTPATH/shell.bash

  source $DOTPATH/applications.bash
  source $DOTPATH/git.bash
fi

sourceif ~/.extras.bash
