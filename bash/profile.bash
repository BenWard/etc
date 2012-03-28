# Generic Shell Defaults
umask 0007

## Terminal
export TERM=xterm-256color
export CLICOLOR=yes

## Editor
export EDITOR="subl -w"

# Improve history handling
export HISTCONTROL=erasedups
export HISTSIZE=10000
export HISTIGNORE="&:ls.*:[bf]g:exit:[ \t]*:git add.*:history:resource"
shopt -s histappend

# Prompt
#export PS1="\[\033[${MACHINECOLOR}m\]\u@\h \[\033[0;33m\]\w $ \[\033[0m\]"
if [ "$USER" = "root" ]; then
  PS1='\[\e[1;31m\]\u@\h \W[\033[34m\]$(__git_ps1 "#%s")\[\033[00m\]\$\[\e[0m\] #'
else
  PS1='\[\e[${MACHINECOLOR}m\]\u@\h \[\e[0;33m\]\w$(__git_ps1 "\[\e[0;31m\]#\[\e[4;31m\]%s")\[\e[0m\] \$ '
fi