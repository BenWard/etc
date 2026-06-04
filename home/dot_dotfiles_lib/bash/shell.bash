# Generic Shell Defaults
umask 0007

## Editor
export EDITOR="code -w"

export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=50000
export HISTFILESIZE=100000
export INPUTRC="${INPUTRC:-$HOME/.inputrc}"

shopt -s checkwinsize
shopt -s cmdhist
shopt -s histappend

bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"
bind "set colored-stats on"
