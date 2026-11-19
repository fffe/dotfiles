# shared bash/zsh initialization
# profiles and rc files may both source this
# not for interactive setup
if [[ -n ${_DOTFILES_SHELL_DIR-} ]]; then
  return 0
fi

if [[ -n ${ZSH_VERSION-} ]]; then
  typeset -g _DOTFILES_SHELL_DIR="${${(%):-%x}:A:h}"
  source "${_DOTFILES_SHELL_DIR%/*}/.zsh/compat.zsh"
else
  _DOTFILES_SHELL_DIR=$(CDPATH='' builtin cd -P -- "${BASH_SOURCE[0]%/*}" && builtin pwd)
  source "${_DOTFILES_SHELL_DIR%/*}/.bash/compat.sh"
fi

# Login startup can move inherited user paths behind system paths on macOS.
# Move managed entries to the front without reordering the rest.
_dotfiles_path=:${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}:
_dotfiles_bins=()
if [[ $OSTYPE == darwin* && -x /opt/homebrew/bin/brew ]]; then
  if [[ -d /opt/homebrew/sbin ]]; then
    _dotfiles_bins+=(/opt/homebrew/sbin)
  fi
  _dotfiles_bins+=(/opt/homebrew/bin)
fi
for _dotfiles_bin in "${_dotfiles_bins[@]}" "$HOME/.local/bin" "$HOME/bin"; do
  while [[ $_dotfiles_path == *:"$_dotfiles_bin":* ]]; do
    _dotfiles_path=${_dotfiles_path/:"$_dotfiles_bin":/:}
  done
  _dotfiles_path=":$_dotfiles_bin$_dotfiles_path"
done
_dotfiles_path=${_dotfiles_path#:}
export PATH=${_dotfiles_path%:}
unset _dotfiles_path _dotfiles_bins _dotfiles_bin

# Suppress inherited invalid locale categories while discovering installed locales.
export LC_ALL=C
_dotfiles_locale() {
  local candidate selected=C
  while IFS= read -r candidate; do
    case $candidate in
      [Cc].UTF-8|[Cc].utf8) selected=$candidate; break ;;
      en_US.UTF-8|en_US.utf8) selected=$candidate ;;
    esac
  done <<< "$(LC_ALL=C command locale -a 2>/dev/null)"

  export LANG=$selected
  unset LC_ALL LC_CTYPE LC_COLLATE LC_MESSAGES LC_NUMERIC LC_TIME LC_MONETARY \
    LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION LANGUAGE
  if [[ $selected == C && $- == *i* ]]; then
    printf '%s\n' 'shell: neither C.UTF-8 nor en_US.UTF-8 is available; using C.' >&2
  fi
}
_dotfiles_locale
unset -f _dotfiles_locale
