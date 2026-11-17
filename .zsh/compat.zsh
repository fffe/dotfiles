typeset -gA _DOTFILES_COLORS _SHADE_CONTEXT
zmodload zsh/system

_shell_has_command() { (( $+commands[$1] )); }
_shell_get() { REPLY=${(P)1}; }
_shell_pid() { REPLY=$sysparams[pid]; }
_shell_directory() { [[ -d $1 ]] || return; REPLY=${1:A}; }
_shell_lines() { reply=("${(@f)1}"); }
_shell_color_count() {
  zmodload zsh/terminfo 2>/dev/null
  REPLY=${terminfo[colors]:-0}
}

_shell_fzf_bindings() {
  local map key line
  local -a restore words

  for map in emacs viins vicmd; do
    for key in '^T' '\ec'; do
      restore+=("$(bindkey -L -M "$map" "$key")")
    done
  done

  source "$1"

  for line in "${restore[@]}"; do
    words=("${(@Q)${(z)line}}")
    builtin bindkey "${(@)words[2,-1]}"
  done
}
