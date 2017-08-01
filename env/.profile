# .bash_profile
#
# @(#) $Id: .profile 2455 2012-01-29 00:09:16Z cunnie $
#

# User specific environment and startup programs

USERNAME=""
[ -x /usr/bin/hostname ] || [ -x /bin/hostname ] && export HOSTNAME=$(hostname)

export _OS="$(uname -s)"
if [ "$_OS" = "Linux" ]; then
  export _DIST=""
  if [ -r /etc/lsb-release ]; then
    _DIST="Ubuntu"
  else 
    if [ -r /etc/redhat-release ]; then
      _DIST="RedHat"
    fi
  fi
fi
  
#export TTY=$(tty)
#export TTY=asdf
#TTY=${TTY:none}
set +o nounset

export USERNAME PATH

# Set up the search paths:
PATH=$PATH:$HOME/bin
if [ "$_OS" = "HP-UX" ]; then
	export PATH=/sbin:/usr/sbin:${PATH}:.
else
if [ "$_OS" = "FreeBSD" ]; then
  # Updated path fbsd9
  export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:$HOME/bin;
  # FreeBSD uses USER not LOGNAME
  export LOGNAME=$USER
  # 2011.08.06 cunnie - (11 years) git needs this for colors
  export GIT_PAGER=less
  export LESS="-eRX"
else
if [ "$_OS" = "Linux" ]; then
  export PATH=/sbin:/usr/sbin:${PATH}:${HOME}/ucb:/usr/local/bin:.
else
if [ "$_OS" = "Darwin" ]; then
  export PATH=$PATH:${HOME}/bin:.
fi
fi
fi
fi

# Set up the shell environment:
#set -u  # 2011.01.11 this blows ubuntu 10.10 up
trap "echo 'logout'" 0

if [ "$_OS" = "HP-UX" ]
then 
  export EDITOR=vi
else
  export EDITOR=vim
  export PAGER=less
  export BLOCKSIZE=K
fi

export ENV=${HOME}/.bashrc
export BASH_ENV=${HOME}/.bashrc
#export HISTFILE=$HOME/.bash_history-${TTY//\//_}
#export HISTFILE=$HOME/.bash_history
#export HISTSIZE=5000
# 2008.12.19 # of commands saved in history file, different
#   than num commands saved in volatile.
#export HISTTIMEFORMAT="%F %T "
#export HISTFILESIZE=5000
export UNIX95=XPG4
# 2/19/06 following need for fbsd fetch passwd prompt
export HTTP_AUTH='basic:*'

## bash stuff
##if [ "${SHELL##*/}X" = bashX ];
if [ "${0##*/}X" = bashX -o "${0##*/}X" = "-bashX" ];
    then . "$BASH_ENV"
else
    print -- "$0"
fi
