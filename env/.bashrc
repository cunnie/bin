#
# $Id: .bashrc 2552 2012-04-10 23:48:52Z cunnie $
#
# My basic niceties
#

#set -o vi
# 2007-10-13 cunnie - for some reason ubuntu sets this wrong.
set +o nounset

# 2011.08.06 cunnie - stealing Pivotal's History
export HISTCONTROL=ignoredups;
shopt -s histappend;
PROMPT_COMMAND='history -a';

## set some reasonable defaults first
##if [  "$TERM" = "xterm"  -o  "$TERM" = "xterm-color" ) -o  "$TERM" = "screen"  ]; then
##if [  "$TERM" = "xterm"  -o  "$TERM" = "xterm-color" ]; then
#if [[  "$TERM" = "xterm" || "$TERM" = "xterm-color" || "$TERM" = "screen"  ]]; then
#  # set good titlebar in bash freebsd
#  PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"'
#  alias ls="/bin/ls -GCs"
#else
#  PS1=" ${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~} $ "
#  alias ls="/bin/ls -FCs"
#fi

# Set up the terminal for hpux:
if [ "$_OS" = "HP-UX" ]; then
  if [ ! "$DT" ]; then
    if [ "$TERM" = "" ]
    then
      eval ` tset -s -Q -m ':?hp' `
    else
      eval ` tset -s -Q `
    fi
    stty erase "^H" kill "^U" intr "^C" eof "^D" susp "^Z"
    stty hupcl ixon ixoff
    tabs
  fi
fi

if [ "$_OS" = "Linux" ]; then
  # only root can read logs in linux
  alias mail="sudo less /var/log/maillog"
  alias mailtail="sudo tail -n 50 -f /var/log/maillog"
  alias sys="sudo less /var/log/messages"
  alias systail="sudo tail -n 50 -f /var/log/messages"
  if [[ "$TERM" = "xterm" || "$TERM" = xterm-color || "$TERM" = screen || "$TERM" = linux ]]; then
    alias mutt="TERM=linux mutt"
    alias ls="/bin/ls -Cs --color"
  fi
#else
#	alias ls="/bin/ls -aCsF"
fi

if [ "$_OS" = "Linux" ] && [ "$_DIST" = "Ubuntu" ]; then
  alias sys="sudo less /var/log/syslog"
  alias systail="sudo tail -n 50 -f /var/log/syslog"
fi

if [ "$_OS" = "FreeBSD" ]; then
  alias mail="less /var/log/maillog"
  alias mailtail="tail -n 50 -f /var/log/maillog"
  alias sys="less /var/log/messages"
  alias systail="tail -n 50 -f /var/log/messages"
fi

if [ "$_OS" = "Darwin" ]; then
  alias sys="less /var/log/system.log"
  alias systail="tail -n 50 -f /var/log/system.log"
fi

if [ "$_OS" = "HP-UX" ]; then
  umask 022
  alias pg=more
  alias cons="hpterm -iconic -map -C -xrm '*mapOnOutputDelay: 1' -T console -n console"
  alias mail="more /var/adm/syslog/mail.log"
  alias mailtail="tail -n 50 -f /var/adm/syslog/mail.log"
  alias sys="more /var/adm/syslog/syslog.log"
  alias systail="tail -n 50 -f /var/adm/syslog/syslog.log"
  alias 5p4="ssh indra /usr/local/sbin/5pquarter | lp -d5p_raw"
else
  # FreeBSD & LINUX use user-private groups
  umask 002
  alias df="/bin/df -k"
  alias ll="ls -l"
fi

# common
alias rdi="cd ~/env; rdist -P ssh; cd -"
alias rsz='eval $(resize)'
alias sh="/usr/bin/sh"
alias vims="vim +set\ tw=68 +\'\'"
alias egs='ps -ef | grep -v grep | egrep -i '
alias svnkey='svn propset svn:keywords "Id Date Revision Author"'
#
alias mrcs='if [[ ! -d RCS ]]; then sudo mkdir RCS; sudo chmod 775 RCS; fi'
#
_HOST=$HOSTNAME
_HOST=${_HOST%%.*}
if [ $(/usr/bin/id -u) -eq 0 ]
  then TAG="#"
  else TAG="$"
fi
if [ "$_OS" = "HP-UX" ]
then
  # HP-UX handles reverse-video okay; nobody else does
  REVERSE=$(tput rev)
  NORMAL=$(tput rmso)
  export PS1="$REVERSE ${_HOST} $LOGNAME $TAG $NORMAL "
else
  #export PS1=" ${_HOST} $LOGNAME $TAG "
  parse_git_branch() {
   git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
  }
  export -f parse_git_branch

  export CLICOLOR=1
  export CLICOLOR_FORCE=1  # ls produces color even to non-ttys
  export PS1="\[\033[36m\]\h:\W \[\033[33m\]\$(parse_git_branch)\[\033[00m\]$\[\033[00m\] "
  export SUDO_PS1='\[\e[0;31m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[0;31m\]\$ \[\e[0m\]'
fi

if [ -f ~/alias.work ]
then 
  . ~/alias.work
fi

# 2009-12-18 tata has svn renamed to avoid upgrading svn workspaces
#[[ $_HOST == "tata" ]] && alias svn='svn-orig'

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
