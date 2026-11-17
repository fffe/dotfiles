# reapply terminal styling, pager policy, and aliases when the rc file is reloaded
# bash loads function definitions before these aliases can expand in them
source "$_DOTFILES_SHELL_DIR/colors.sh"
export LESS=MieR
# keep man overstrikes for less; strip them before syntax highlighting.
export GROFF_NO_SGR=1

_dotfiles_pager() {
  local binary manpager

  if _shell_has_command bat; then binary=bat
  elif _shell_has_command batcat; then binary=batcat
  else
    case ${PAGER%% *} in
      bat|batcat)
        for binary in less more cat; do
          if _shell_has_command "$binary"; then export PAGER=$binary; break; fi
        done
        ;;
    esac
    case ${MANPAGER-} in
      bat\ --plain\ --language=*|batcat\ --plain\ --language=*|sh\ -c\ \'col\ -b\ \|\ bat*) unset MANPAGER ;;
    esac
    return 0
  fi

  if [[ -z ${BAT_THEME-} && ${_DOTFILES_COLORS[palette]} == ansi ]]; then
    export BAT_THEME=ansi
  fi

  case ${PAGER%% *} in
    bat|batcat) export PAGER="$binary --plain --language=txt --paging=always" ;;
  esac

  manpager="$binary --plain --language=txt --color=never --paging=always"

  if [[ ${_DOTFILES_COLORS[palette]} != ansi ]] && _shell_has_command col; then
    manpager="sh -c 'col -b | $binary --plain --language=man --paging=always'"
  fi

  case ${MANPAGER-} in
    ''|bat\ --plain\ --language=*|batcat\ --plain\ --language=*|sh\ -c\ \'col\ -b\ \|\ bat*) export MANPAGER=$manpager ;;
  esac
}
_dotfiles_pager
unset -f _dotfiles_pager

if _shell_has_command nvim; then
  alias vim=nvim vi=nvim
fi

alias egrep='command grep -E --color=auto'
alias fgrep='command grep -F --color=auto'
alias grep='command grep --color=auto'
alias ls='command ls --color=auto -F'
alias ll='ls -lh'
alias la='ls -lhA'

if [[ -n ${ZSH_VERSION-} ]]; then
  alias hr='builtin fc -RI'
else
  alias hr='builtin history -n'
fi

h() {
  local count=${1-20}
  if (( $# > 1 )) || [[ $count == *[!0-9]* || $count != [1-9]* ]]; then
    builtin printf 'usage: h [positive count]\n' >&2
    return 2
  fi
  if [[ -n ${ZSH_VERSION-} ]]; then
    builtin fc -l "-$count"
  else
    builtin history "$count"
  fi
}

if ! _shell_has_command rg && _shell_has_command ripgrep; then alias rg=ripgrep; fi
if ! _shell_has_command bat && _shell_has_command batcat; then alias bat=batcat; fi
