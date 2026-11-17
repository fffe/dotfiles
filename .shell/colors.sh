# Shared terminal palette and tool colors. Source after init.sh.
# Named modern terminals are trusted; a tmux server supplies its fixed palette.
if [ "${COLORTERM-}" = 24bit ]; then
  export COLORTERM=truecolor
fi

case ${TERM:-dumb} in
  dumb|linux|vt*|cons*|ansi)
    unset COLORTERM
    ;;
  xterm-256color|xterm-ghostty|ghostty|ms-terminal|nsterm-256color)
    export COLORTERM=truecolor
    ;;
esac

_dotfiles_colors() {
  local blue=cyan coral=cyan blue_sgr=36 coral_sgr=36
  local green=green yellow=yellow
  local green_sgr=32 yellow_sgr=33
  local selection='fg=white,bg=blue' menu='0;37;44' emphasis='0;30;43'
  local search_path=36 search_match='0;30;46'
  local palette=ansi REPLY=0

  case ${TMUX:+${DOTFILES_TMUX_COLORS-}} in
    truecolor|256|ansi) palette=$DOTFILES_TMUX_COLORS ;;
    *)
      if [[ ${COLORTERM-} == truecolor ]]; then
        palette=truecolor
      elif [[ ${TERM-} == *256color ]]; then
        palette=256
      else
        _shell_color_count
        (( REPLY >= 256 )) && palette=256
      fi
      ;;
  esac

  case $palette in
    truecolor)
      blue='#adccff' coral='#ffb5a9'
      green='#00ad3e' yellow='#c4c200'
      green_sgr='38;2;0;173;62' yellow_sgr='38;2;196;194;0'
      blue_sgr='38;2;173;204;255' coral_sgr='38;2;255;181;169'
      selection='fg=default,bg=#31486d' menu='0;39;48;2;49;72;109'
      emphasis='0;38;2;8;13;22;48;2;255;181;169'
      search_path='38;2;137;180;250' search_match='0;38;2;12;12;12;48;2;148;226;213'
      ;;
    256)
      blue=153 coral=217
      green=35 yellow=184
      green_sgr='38;5;35' yellow_sgr='38;5;184'
      blue_sgr='38;5;153' coral_sgr='38;5;217'
      selection='fg=default,bg=24' menu='0;39;48;5;24'
      emphasis='0;38;5;232;48;5;217'
      search_path='38;5;111' search_match='0;38;5;232;48;5;158'
      ;;
  esac

  _DOTFILES_COLORS=(
    [blue]="$blue" [coral]="$coral" [palette]="$palette"
    [blue_sgr]="$blue_sgr" [coral_sgr]="$coral_sgr"
    [green]="$green" [yellow]="$yellow"
    [green_sgr]="$green_sgr" [yellow_sgr]="$yellow_sgr"
    [selection]="$selection" [menu]="$menu"
  )

  export GREP_COLOR=$search_match
  export GREP_COLORS="mt=${search_match}:fn=0;${search_path}:ln=0:bn=0:se=0:sl=:cx="
  export LESS_TERMCAP_mb=$'\e['"0;${coral_sgr}m"
  export LESS_TERMCAP_md=$'\e[0;1m'
  export LESS_TERMCAP_me=$'\e[0m' LESS_TERMCAP_se=$'\e[0m' LESS_TERMCAP_ue=$'\e[0m'
  export LESS_TERMCAP_so=$'\e['"${emphasis}m"
  export LESS_TERMCAP_us=$'\e['"0;4;${blue_sgr}m"

  # preserve external ripgrep config; only replace one selected by these dotfiles.
  local config_root="${_DOTFILES_SHELL_DIR%/*}/.config/terminal-colors"
  if [[ -z ${RIPGREP_CONFIG_PATH-} || $RIPGREP_CONFIG_PATH == "$config_root"/ripgrep/*.conf ]]; then
    export RIPGREP_CONFIG_PATH="$config_root/ripgrep/$palette.conf"
  fi

  # replace our inherited include instead of appending one in every nested shell.
  case ${GIT_CONFIG_COUNT:-0} in ''|*[!0-9]*) return 0 ;; esac
  local count=$((10#${GIT_CONFIG_COUNT:-0})) index key value
  for (( index=0; index<count; index++ )); do
    _shell_get "GIT_CONFIG_KEY_$index"; key=$REPLY
    _shell_get "GIT_CONFIG_VALUE_$index"; value=$REPLY
    [[ $key == include.path && $value == "$config_root"/git/*.conf ]] && break
  done

  export "GIT_CONFIG_KEY_$index=include.path"
  export "GIT_CONFIG_VALUE_$index=$config_root/git/$palette.conf"
  export GIT_CONFIG_COUNT=$(( index == count ? count + 1 : count ))
}
_dotfiles_colors
unset -f _dotfiles_colors

# preserve explicit ls colors, including an intentionally empty LS_COLORS.
_dotfiles_ls_colors() {
  local tool setup file=''

  if [[ ! ${LS_COLORS+x} ]]; then
    for tool in dircolors gdircolors; do
      _shell_has_command "$tool" || continue

      for file in "$HOME/.dircolors" "$HOME/.dir_colors"; do
        [[ -r $file ]] && break
      done

      if [[ -r $file ]]; then
        setup=$(command "$tool" -b "$file") && builtin eval "$setup"
      elif setup=$(TERM=xterm command "$tool" -b); then
        builtin eval "$setup"
        LS_COLORS=${LS_COLORS//01;/0;}
        LS_COLORS=${LS_COLORS//di=0;34/di=0;${_DOTFILES_COLORS[blue_sgr]}}
      fi  
      break
    done

    export LS_COLORS=${LS_COLORS-"rs=0:di=0;${_DOTFILES_COLORS[blue_sgr]}:ln=0;36:ex=0;32:pi=0;33:so=0;35:bd=0;33:cd=0;33:or=0;31:mi=0;31:su=0;37;41:sg=0;30;43:tw=0;30;42:ow=0;30;43:st=0;37;44"}
  fi

  export LSCOLORS=${LSCOLORS-gxfxfxdxcxdxdxabadacad}
}
_dotfiles_ls_colors
unset -f _dotfiles_ls_colors
