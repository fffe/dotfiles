# prompt data and colors shared by bash and zsh
# rendering and hooks live in each shell's config
# callers must escape data for their prompt syntax and strip terminal controls
_shade_prompt_colors() {
  typeset -gA _SHADE_COLORS
  local user host directory separator context role value sgr

  case ${_DOTFILES_COLORS[palette]} in
    truecolor)
      user=e8aab7 host=dccccf directory=a8bdd8 separator=eab8c2 ;;
    256)
      user=181 host=252 directory=146 separator=217 ;;
    *) user=7 host=7 directory=6 separator=7 ;;
  esac

  context=$host
  local -A colors=([user]="$user" [host]="$host" [directory]="$directory" [separator]="$separator" [context]="$context")
  _SHADE_COLORS=()

  for role in user host directory separator context; do
    value=${colors[$role]}
    case ${_DOTFILES_COLORS[palette]} in
      truecolor)
        sgr="38;2;$((16#${value:0:2}));$((16#${value:2:2}));$((16#${value:4:2}))"
        ;;
      256) sgr="38;5;$value" ;;
      *) sgr=$((value < 8 ? 30 + value : 90 + value - 8)) ;;
    esac
    _SHADE_COLORS[${role}_sgr]=$sgr
  done

  _SHADE_COLORS[prompt_sgr]=${_DOTFILES_COLORS[coral_sgr]}
  if [[ ${_DOTFILES_COLORS[palette]} == ansi ]]; then
    _SHADE_COLORS[prompt_sgr]=37
  fi
}
_shade_prompt_colors
unset -f _shade_prompt_colors

_shade_git() {
  local listing line branch='' oid='' human='' counts
  local ahead=0 behind=0 detached=0 clean=1
  local -a reply

  listing=$(GIT_OPTIONAL_LOCKS=0 command git status --porcelain=v2 --branch 2>/dev/null) || return 0
  [[ -n $listing ]] || return 0

  _shell_lines "$listing"
  for line in "${reply[@]}"; do
    case $line in
      '# branch.head '*) branch=${line#\# branch.head }; [[ $branch != '(detached)' ]] || detached=1 ;;
      '# branch.oid '*) oid=${line#\# branch.oid } ;;
      '# branch.ab '*)
        counts=${line#\# branch.ab }
        ahead=${counts%% *}; ahead=${ahead#+}
        behind=${counts##* }; behind=${behind#-}
        ;;
      1\ *|2\ *|u\ *|\?\ *) clean=0 ;;
    esac
  done

  [[ -n $branch ]] || return 0
  
  local icon='󰘬' target=$branch state='󰸞' divergence=''
  if (( detached )); then
    human=$(command git describe --tags --always --exact-match --abbrev=8 2>/dev/null)
    target=${human:-${oid:0:8}}
    icon='󰁥'
  fi

  (( clean )) || state='󱎘'

  if (( ahead && behind )); then
    divergence=" ${behind}${ahead}"
  elif (( ahead )); then
    divergence=" $ahead"
  elif (( behind )); then
    divergence=" ${behind}"
  fi

  builtin printf '%s %s%s %s' "$icon" "$target" "$divergence" "$state"
}

_shade_version_file() {
  local directory filename=$2
  _shell_directory "$1" || return 1
  directory=$REPLY
  REPLY=''

  while true; do
    if [[ -f $directory/$filename && ( $filename != .ruby-version || -s $directory/$filename ) ]]; then
      REPLY=$directory/$filename
      return 0
    fi
  
    [[ $directory != / ]] || return 1
    directory=${directory%/*}
    directory=${directory:-/}
  done
}

_shade_languages() {
  [[ -z ${ZSH_VERSION-} ]] || emulate -L zsh
  local language root directory filename version word rest executable REPLY output=''

  for language in ruby python; do
    case $language in
      ruby)
        root=${RBENV_ROOT:-$HOME/.rbenv}
        directory=${RBENV_DIR:-$PWD} filename=.ruby-version version=${RBENV_VERSION-}
        ;;
      python)
        [[ -z ${VIRTUAL_ENV-}${CONDA_PREFIX-} ]] || continue
        root=${PYENV_ROOT:-$HOME/.pyenv}
        directory=${PYENV_DIR:-$PWD} filename=.python-version version=${PYENV_VERSION-}
        ;;
    esac

    executable=$(command -v -- "$language") || continue
    [[ $executable -ef $root/shims/$language ]] || continue

    if [[ -z $version ]]; then
      _shade_version_file "$directory" "$filename" || _shade_version_file "$PWD" "$filename" || continue
      [[ -r $REPLY ]] || continue
      while IFS=$' \t\r' read -r word rest || [[ -n $word ]]; do
        [[ -n $word ]] || continue
        [[ $language != python || $word != \#* ]] || continue
        version+=${version:+:}$word
        [[ $language != ruby ]] || break
      done < "$REPLY"
    fi

    version=${version//[$'\001'-$'\037'$'\177']/}
    [[ -z $version || $version == system ]] || output+=$language$'\t'$version$'\n'
  done
  builtin printf '%s' "$output"
}

_shade_context() {
  local tf_dir=${TF_DATA_DIR:-.terraform} workspace=default
  local tf='' venv=${VIRTUAL_ENV-}
  local perl=${PERLBREW_PERL-} node='' conda=''

  if [[ -d $tf_dir ]]; then
    if [[ -n ${TF_WORKSPACE-} ]]; then
      workspace=$TF_WORKSPACE
    elif [[ -r $tf_dir/environment ]]; then
      IFS= builtin read -r workspace < "$tf_dir/environment"
    fi
    tf=$workspace
  fi

  venv=${venv%/}

  [[ -z $perl ]] || perl=${perl#perl-}${PERLBREW_LIB:+@$PERLBREW_LIB}

  if [[ -n ${NVM_BIN-} ]]; then
    node=${NVM_BIN%/}
    node=${node%/bin}
    node=${node##*/}
  fi

  if [[ -n ${CONDA_PREFIX-} ]]; then
    conda=${CONDA_DEFAULT_ENV:-$CONDA_PREFIX}
    conda=${conda%/}
    conda=${conda##*/}
  fi

  _SHADE_CONTEXT=([tf]="$tf" [venv]="${venv##*/}" [perl]="$perl" [node]="$node" [conda]="$conda")
}

_shade_emit_title() {
  case ${TERM-} in
    xterm*|nsterm*|ghostty|ms-terminal)
      builtin printf '\e]1;%s\a\e]2;%s\a' "$1" "$2"
      ;;
    tmux*)
      [[ -n ${TMUX-} ]] || return 0
      builtin printf '\ek%s\e\\\e]0;%s\a' "$1" "$2" ;;
    screen*)
      [[ -n ${TMUX-}${STY-} ]] || return 0
      builtin printf '\ek%s\e\\' "$1" ;;
    *) return 1 ;;
  esac
}
