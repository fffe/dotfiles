[[ $- == *i* ]] || return
if (( BASH_VERSINFO[0] < 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] < 2) )); then
  return
fi

case ${BASH_SOURCE[0]} in
  */*) source "${BASH_SOURCE[0]%/*}/.shell/init.sh" ;;
  *) source ./.shell/init.sh ;;
esac
if (( SHLVL == 1 )) && ! shopt -q login_shell; then
  source "$_DOTFILES_SHELL_DIR/profile.sh"
fi

HISTFILE=$HOME/.bash_history
HISTSIZE=5000 HISTFILESIZE=5000
HISTCONTROL=ignoredups
shopt -s histappend cmdhist lithist checkwinsize
TIMEFORMAT=$'real\t%3Rs\nuser\t%3Us\nsys \t%3Ss\ncpu \t%P'

for fn in "$_DOTFILES_SHELL_DIR"/functions/*; do source "$fn"; done
unset fn
source "${_DOTFILES_SHELL_DIR%/*}/.bash/functions.sh"
source "$_DOTFILES_SHELL_DIR/interactive.sh"

if ! declare -F _completion_loader >/dev/null; then
  for completion in /usr/share/bash-completion/bash_completion \
    /opt/homebrew/etc/profile.d/bash_completion.sh \
    /usr/local/etc/profile.d/bash_completion.sh /etc/bash_completion; do
    if [[ -r $completion ]]; then
      source "$completion"
      break
    fi
  done
  unset completion
fi
source "${_DOTFILES_SHELL_DIR%/*}/.bash/editing.sh"
source "$_DOTFILES_SHELL_DIR/fzf.sh"
source "${_DOTFILES_SHELL_DIR%/*}/.bash/prompt.sh"

[[ ! -r $HOME/.bashrc.local ]] || source "$HOME/.bashrc.local"
