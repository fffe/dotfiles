setopt ALWAYS_TO_END        # move cursor to end of word after completion
setopt AUTO_PUSHD           # add the previous directory to the stack on cd
setopt COMPLETE_IN_WORD     # complete from both ends of a word
setopt CORRECT              # try to correct typos in commands
setopt EXTENDED_GLOB        # adds #, ~ and ^ to globbing
setopt EXTENDED_HISTORY     # adds timestamps and duration to history file
setopt HIST_FCNTL_LOCK      # use fcntl for locking histfile, if available
setopt HIST_FIND_NO_DUPS    # ignore duplicate commands while searching history
setopt HIST_REDUCE_BLANKS   # get rid of unnecessary whitespace
setopt INC_APPEND_HISTORY   # append commands to the shared history immediately
setopt PUSHD_IGNORE_DUPS    # don't add duplicate entries to the stack
setopt PUSHD_SILENT         # don't print directory stack after pushd/popd
setopt PUSHD_TO_HOME        # "pushd" == "pushd $HOME" 

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

source "${ZDOTDIR:-$HOME}/.shell/init.sh"
source "$_DOTFILES_SHELL_DIR/interactive.sh"
source "${ZDOTDIR:-$HOME}/.zsh/completion-style.zsh"

# when escape is pressed twice:
#   - if there is a command in the buffer, prefix it with sudo
#   - if there is no command in the buffer, prefix the last command with sudo
sudo-cmd() {
    [[ -z $BUFFER ]] && zle up-history
    [[ $BUFFER != su(do|)\ * ]] && LBUFFER="sudo $LBUFFER"
}
zle -N sudo-cmd
bindkey -r "\e"
bindkey "\ee" vi-cmd-mode
bindkey "\e\e" sudo-cmd

# shift+return inserts a literal newline
insert-newline() { LBUFFER+=$'\n' }
zle -N insert-newline
for keymap in emacs viins; do
  bindkey -M "$keymap" $'\e[13;2u' insert-newline
  bindkey -M "$keymap" $'\e[27;2;13~' insert-newline
done
unset keymap

# auto-escape urls pasted into line editor (eg curl http://...)
autoload -Uz url-quote-magic && zle -N self-insert url-quote-magic
autoload -Uz bracketed-paste-magic \
    && zle -N bracketed-paste bracketed-paste-magic
 
autoload -Uz compinit && compinit

# some completion defaults
zstyle ':completion::complete:*' use-cache on
zstyle ':completion:*' hosts
zstyle ':completion:*' users
zstyle ':completion:*' force-list always
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
zstyle ':completion:*:matches' group yes
zstyle ':completion:*:options' description yes
zstyle ':completion:*:options' auto-description '%d'

# nicer kill completion, gnu/bsd/sol compatible ps
zstyle ':completion:*:processes' command 'ps -u $USER -o pid,pcpu,tty,time,args'
zstyle ':completion:*:kill:*' insert-ids single
zstyle ':completion:*:kill:*' menu yes select
zstyle ':completion:*:(rm|kill|diff):*' ignore-line yes

# fuzzy match mistyped completions
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# nicer man completion
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# A console needs neither Nerd Font glyphs nor terminal title sequences.
# DOTFILES_PLAIN_PROMPT=1 is also useful through tmux on a console.
if [[ ${DOTFILES_PLAIN_PROMPT:-0} == 1 || ${TERM:-dumb} == (dumb|linux|vt*|cons*|ansi) \
    || ${LC_ALL:-${LC_CTYPE:-${LANG:-C}}} == (C|POSIX) ]]; then
  PROMPT='%n@%m:%~%# '
  RPROMPT=''
  SPROMPT='zsh: correct %R to %r [nyae]? '
elif [[ -d ${ZDOTDIR:-$HOME}/.zsh/prompts ]]; then
  fpath=(${ZDOTDIR:-$HOME}/.zsh/prompts $fpath)
  autoload -Uz promptinit && promptinit && prompt shade
fi

# load functions
[[ -d ${ZDOTDIR:-$HOME}/.zsh/functions ]] && {
  fpath=(${ZDOTDIR:-$HOME}/.zsh/functions "$_DOTFILES_SHELL_DIR/functions" $fpath)
  for fn in ${ZDOTDIR:-$HOME}/.zsh/functions/* "$_DOTFILES_SHELL_DIR"/functions/*; do autoload -Uz ${fn:t} ; done
  unset fn
}

source "$_DOTFILES_SHELL_DIR/fzf.sh"

# zsh-users/zsh-history-substring-search master at a0bdb0d47dbaba31dba2db7af8c48a5d9c74049a
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="${_DOTFILES_COLORS[selection]}"
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="fg=${_DOTFILES_COLORS[coral]},bold"
source "${ZDOTDIR:-$HOME}/.zsh/vendor/zsh-history-substring-search/zsh-history-substring-search.zsh"

# Accept arrows in both normal and application cursor modes.
for keymap in emacs viins vicmd; do
  bindkey -M "$keymap" $'\e[A' history-substring-search-up
  bindkey -M "$keymap" $'\e[B' history-substring-search-down
  bindkey -M "$keymap" $'\eOA' history-substring-search-up
  bindkey -M "$keymap" $'\eOB' history-substring-search-down
done
unset keymap

# load local configuration if it exists
[[ -e ${HOME}/.zshrc.local ]] && source ${HOME}/.zshrc.local
