DOTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Use https://github.com/mrzool/bash-sensible as a base:
source $DOTPATH/sensible/sensible.bash

source $DOTPATH/terminal.bash
source $DOTPATH/machine.bash

source $DOTPATH/paths.bash
source $DOTPATH/completions.bash
source $DOTPATH/functions.bash

source $DOTPATH/profile.bash

source $DOTPATH/applications.bash
source $DOTPATH/fuck.bash
source $DOTPATH/git.bash
source $DOTPATH/pants.bash

source $DOTPATH/node.bash
source $DOTPATH/ruby.bash
source $DOTPATH/scala.bash

sourceif ~/.extras.bash