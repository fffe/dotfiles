# Split PAGER into literal arguments, without evaluating shell expansions.
_bash_pager_words() {
  local input=$1 word='' quote='' character next started=0 index
  pager=()
  for (( index=0; index<${#input}; index++ )); do
    character=${input:index:1}
    if [[ $quote == "'" ]]; then
      if [[ $character == "'" ]]; then quote=''; else word+=$character; fi
    elif [[ $character == \\ && $quote != "'" ]]; then
      (( ++index < ${#input} )) || return 2
      next=${input:index:1}
      [[ $next == $'\n' ]] && continue
      if [[ $quote == '"' && $next != [\$\`\"\\] ]]; then word+="\\"; fi
      word+=$next
      started=1
    elif [[ $quote == '"' ]]; then
      if [[ $character == '"' ]]; then quote=''; else word+=$character; fi
    else
      case $character in
        "'"|'"') quote=$character; started=1 ;;
        ' '|$'\t'|$'\n')
          if (( started )); then pager+=("$word"); word=''; started=0; fi
          ;;
        *) word+=$character; started=1 ;;
      esac
    fi
  done
  [[ -z $quote ]] || return 2
  (( ! started )) || pager+=("$word")
  (( ${#pager[@]} > 0 ))
}

rgl() {
  local search=rg
  if ! _shell_has_command rg; then
    if _shell_has_command ripgrep; then search=ripgrep
    else builtin printf '%s\n' 'rgl: ripgrep is not installed' >&2; return 127
    fi
  fi
  if [[ ! -t 1 ]]; then command "$search" "$@"; return $?; fi
  local -a pager results
  if ! _bash_pager_words "${PAGER:-less -R}"; then
    builtin printf '%s\n' 'rgl: invalid PAGER arguments' >&2
    return 2
  fi
  command "$search" --color=always --line-number "$@" | command "${pager[@]}"
  results=("${PIPESTATUS[@]}")
  (( results[1] == 0 )) || return "${results[1]}"
  (( results[0] == 141 )) && return 0
  return "${results[0]}"
}
