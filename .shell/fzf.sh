# install history search after the shell's editing bindings; leave other keys alone
_dotfiles_fzf() {
  _shell_has_command fzf || return 0
  local shell=bash binary prefix directory script='' integration

  if [[ -n ${ZSH_VERSION-} ]]; then
    shell=zsh
    binary=${commands[fzf]}
  else
    binary=$(builtin type -P fzf)
  fi

  prefix=${binary%/*}/..

  for directory in \
    "$prefix/share/fzf" "$prefix/share/fzf/shell" \
    "$prefix/share/doc/fzf/examples" "$prefix/share/doc/fzf" \
    "$prefix/shell" "$prefix/opt/fzf/shell" \
    "$HOME/.fzf/shell" /usr/share/fzf /usr/share/fzf/shell \
    /usr/share/doc/fzf/examples /usr/share/doc/fzf; do

    if [[ -r $directory/key-bindings.$shell ]]; then
      script=$directory/key-bindings.$shell
      break
    fi
  done
  if [[ -z $script ]]; then
    integration=$("$binary" "--$shell" 2>/dev/null) || return 0
  fi

  local blue=${_DOTFILES_COLORS[blue]} coral=${_DOTFILES_COLORS[coral]}
  local selected=${_DOTFILES_COLORS[selection]##*bg=} foreground=-1
  if [[ ${_DOTFILES_COLORS[palette]} == ansi ]]; then
    blue=6; coral=3; selected=4; foreground=7
  fi

  # refresh only our prefix on reload; retain user-supplied ctrl-r options
  local fzf_options=${FZF_CTRL_R_OPTS-}
  if [[ -n ${_DOTFILES_FZF_DEFAULTS-} ]]; then
    fzf_options=${fzf_options#"$_DOTFILES_FZF_DEFAULTS"}
    fzf_options=${fzf_options# }
  fi

  _DOTFILES_FZF_DEFAULTS="--height=10 --layout=default --info=inline --border=rounded --no-bold"
  # The history widget puts the event number in the first field.
  _DOTFILES_FZF_DEFAULTS+=" --bind='alt-enter:execute($shell -c {2..})+abort'"
  case ${LC_ALL:-${LC_CTYPE:-${LANG:-C}}} in
    C|POSIX) _DOTFILES_FZF_DEFAULTS+=' --no-unicode' ;;
  esac

  _DOTFILES_FZF_DEFAULTS+=" --color=base16,fg:-1,bg:-1,hl:$coral,fg+:$foreground,bg+:$selected,hl+:$coral"
  _DOTFILES_FZF_DEFAULTS+=",info:$blue,border:$blue,prompt:$coral,pointer:$coral,marker:$coral,spinner:$coral,header:$blue"
  export _DOTFILES_FZF_DEFAULTS
  export FZF_CTRL_R_OPTS="$_DOTFILES_FZF_DEFAULTS${fzf_options:+ $fzf_options}"

  # these locals are consumed by fzf's sourced script
  local FZF_CTRL_T_COMMAND='' FZF_ALT_C_COMMAND=''
  if [[ -n $script ]]; then
    _shell_fzf_bindings "$script"
  else
    _shell_fzf_bindings <(builtin printf '%s\n' "$integration")
  fi
}
_dotfiles_fzf
unset -f _dotfiles_fzf
