export CHROME_BIN=/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome

# Guess what I meant
if [[ -x "$(command -v thefuck)" ]]; then
  alias f='$(thefuck $(fc -ln -1))'
fi

# VirtualBox management
if [[ -x "$(command -v VBoxManage)" ]]; then
  alias vb=VBoxManage
fi


# Open Sublime Project
if [[ -x "$(command -v subl)" ]]; then
  function subl {
    if [ -n "$1" ]; then
      command subl $1
    elif [ -f *.sublime-project ]; then
      command subl *.sublime-project
    else
      command subl .
    fi
  }
fi

# Open vscode directory
if [[ -x "$(command -v code)" ]]; then
  function code {
    if [ -n "$1" ]; then
      command code $1
    else
      command code .
    fi
  }
fi

# Open nova
if [[ -x "$(command -v nova)" ]]; then
function nova {
  if [ -n "$1" ]; then
    command nova open $1 --no-wait
  else
    command nova open . --no-wait
  fi
}
fi
