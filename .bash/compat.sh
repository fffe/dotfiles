declare -gA _DOTFILES_COLORS _SHADE_CONTEXT

_shell_has_command() { builtin type -P -- "$1" >/dev/null; }
_shell_get() { REPLY=${!1-}; }
_shell_pid() { REPLY=$BASHPID; }
_shell_directory() { REPLY=$(CDPATH='' builtin cd -P -- "$1" 2>/dev/null && builtin pwd -P); }
_shell_lines() { builtin mapfile -t reply <<< "$1"; }
_shell_color_count() {
  REPLY=0
  _shell_has_command tput && REPLY=$(command tput colors 2>/dev/null)
  [[ $REPLY =~ ^[0-9]+$ ]] || REPLY=0
  return 0
}

_shell_fzf_bindings() {
  local map kind line index key
  local -a restore=()
  for map in emacs-standard vi-command vi-insert; do
    for kind in -p -s -X; do
      while IFS= builtin read -r line; do
        case $line in
          '"\C-z":'*|'"\C-t":'*|'"\ec":'*|'"\er":'*|'"\e(":'*)
            restore+=("$map" "$kind" "$line") ;;
        esac
      done < <(builtin bind -m "$map" "$kind")
    done
  done

  source "$1"

  # Also cover older scripts that cannot disable Ctrl+T/Alt+C.
  for map in emacs-standard vi-command vi-insert; do
    for key in '\C-z' '\C-t' '\ec' '\er' '\e('; do
      builtin bind -m "$map" -r "$key"
    done
  done
  for (( index=0; index<${#restore[@]}; index+=3 )); do
    if [[ ${restore[index+1]} == -X ]]; then
      builtin bind -m "${restore[index]}" -x "${restore[index+2]}"
    else
      builtin bind -m "${restore[index]}" "${restore[index+2]}"
    fi
  done
}
