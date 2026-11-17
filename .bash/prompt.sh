source "$_DOTFILES_SHELL_DIR/prompt-common.sh"

_shade_bash_title() {
  local text=$1 prefix='' tab window
  text=${text//[$'\001'-$'\037'$'\177']/}
  if [[ -n ${STY-}${TMUX-}${SSH_CLIENT-} ]]; then
    prefix="${USER:-${LOGNAME-}}@${HOSTNAME%%.*}: "
    prefix=${prefix//[$'\001'-$'\037'$'\177']/}
  fi
  tab=$text window=$prefix$text
  (( ${#tab} <= 30 )) || tab=${tab:0:27}...
  (( ${#window} <= 60 )) || window=${window:0:57}...
  _shade_emit_title "$tab" "$window" || :
}

_shade_bash_preexec() {
  [[ ${_SHADE_AT_PROMPT:-0} == 1 ]] || return 0
  _SHADE_AT_PROMPT=0
  [[ $1 != _shade_bash_precmd ]] || return 0
  _shade_bash_title "$1"
}

_shade_bash_precmd() {
  local result=$? field value color segment directory=$PWD weight=''
  _SHADE_AT_PROMPT=0
  builtin history -a
  _shade_context
  while IFS=$'\t' builtin read -r field value; do
    case $field in ruby|python) _SHADE_CONTEXT[$field]=$value ;; esac
  done < <(_shade_languages)
  _SHADE_BASH_GIT=$(_shade_git)
  _SHADE_BASH_GIT=${_SHADE_BASH_GIT//[$'\001'-$'\037'$'\177']/}
  _SHADE_BASH_STATE=${_SHADE_BASH_GIT##* }
  _SHADE_BASH_GIT=${_SHADE_BASH_GIT% *}
  PS1='\n\[\e[0m\]\[\e['"${_SHADE_COLORS[user_sgr]}"'m\]\u\[\e['"${_SHADE_COLORS[separator_sgr]}"'m\]@\[\e['"${_SHADE_COLORS[host_sgr]}"'m\]\h\[\e[0m\] \[\e['"${_SHADE_COLORS[directory_sgr]}"'m\]\w\[\e[0m\]'
  if [[ -n $_SHADE_BASH_GIT ]]; then
    color=${_DOTFILES_COLORS[green_sgr]}
    [[ $_SHADE_BASH_STATE != '󱎘' ]] || color=${_DOTFILES_COLORS[yellow_sgr]}
    PS1+=' ${_SHADE_BASH_GIT} \[\e['"$color"'m\]${_SHADE_BASH_STATE}\[\e[0m\]'
  fi
  for field in tf ruby python perl node conda venv; do
    value=${_SHADE_CONTEXT[$field]}
    [[ -n $value ]] || continue
    _SHADE_CONTEXT[$field]=${value//[$'\001'-$'\037'$'\177']/}
    builtin printf -v segment ' \[\e[%sm\]%s\[\e[%sm\]:\[\e[%sm\]${_SHADE_CONTEXT[%s]}\[\e[0m\]' "${_SHADE_COLORS[user_sgr]}" "$field" "${_SHADE_COLORS[separator_sgr]}" "${_SHADE_COLORS[context_sgr]}" "$field"
    PS1+=$segment
  done
  PS1+='\n'
  (( result == 0 )) || weight='1;'
  PS1+='\[\e['"${weight}${_SHADE_COLORS[prompt_sgr]}"'m\]\$\[\e[0m\] '
  case $directory in "$HOME") directory='~' ;; "$HOME"/*) directory="~${directory#"$HOME"}" ;; esac
  _shade_bash_title "$directory"
  _SHADE_AT_PROMPT=1
  return "$result"
}

_shade_bash_setup() {
  local hook
  case ${TERM:-dumb} in dumb|linux|vt*|cons*|ansi) PS1='\u@\h:\w\$ '; return ;; esac
  if [[ ${DOTFILES_PLAIN_PROMPT:-0} == 1 || ${LC_ALL:-${LC_CTYPE:-${LANG:-C}}} == @(C|POSIX) ]]; then
    PS1='\u@\h:\w\$ '
    return
  fi
  VIRTUAL_ENV_DISABLE_PROMPT=1
  export CONDA_CHANGEPS1=false
  for hook in "${PROMPT_COMMAND[@]}"; do
    [[ $hook != _shade_bash_precmd ]] || return 0
  done
  PROMPT_COMMAND+=(_shade_bash_precmd)
  if [[ -z $(trap -p DEBUG) ]]; then
    trap '_shade_bash_preexec "$BASH_COMMAND"' DEBUG
  fi
}
_shade_bash_setup
unset -f _shade_bash_setup
