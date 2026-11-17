_bash_insert_newline() {
  local LC_ALL=C
  READLINE_LINE=${READLINE_LINE:0:READLINE_POINT}$'\n'${READLINE_LINE:READLINE_POINT}
  (( READLINE_POINT += 1 ))
}

_bash_sudo_cmd() {
  local LC_ALL=C
  if [[ -z $READLINE_LINE ]]; then
    READLINE_LINE=$(builtin fc -ln -1 2>/dev/null) || return
    READLINE_LINE=${READLINE_LINE#$'\t'}
    READLINE_POINT=${#READLINE_LINE}
  fi
  case $READLINE_LINE in su\ *|sudo\ *) return ;; esac
  READLINE_LINE="sudo $READLINE_LINE"
  (( READLINE_POINT += 5 ))
}

_bash_quote_word() {
  local LC_ALL=C left right word quoted
  local start=$READLINE_POINT end=$READLINE_POINT
  while (( start > 0 )) && [[ ${READLINE_LINE:start-1:1} != [[:space:]] ]]; do ((start--)); done
  while (( end < ${#READLINE_LINE} )) && [[ ${READLINE_LINE:end:1} != [[:space:]] ]]; do ((end++)); done
  left=${READLINE_LINE:0:start} right=${READLINE_LINE:end}
  word=${READLINE_LINE:start:end-start}
  [[ -n $word ]] || return 0
  builtin printf -v quoted '%q' "$word"
  READLINE_LINE=$left$quoted$right
  READLINE_POINT=$(( start + ${#quoted} ))
}

for keymap in emacs-standard vi-insert; do
  bind -m "$keymap" -x '"\e[13;2u":_bash_insert_newline'
  bind -m "$keymap" -x '"\e[27;2;13~":_bash_insert_newline'
  bind -m "$keymap" -x '"\e\e":_bash_sudo_cmd'
  bind -m "$keymap" -x '"\eq":_bash_quote_word'
  bind -m "$keymap" '"\ee":vi-movement-mode'
done
unset keymap
bind 'set enable-bracketed-paste on'
bind 'set enable-active-region on'
bind "set active-region-start-color \"\e[${_DOTFILES_COLORS[menu]}m\""
bind 'set active-region-end-color "\e[0m"'
bind 'set colored-stats on'
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
