__set_if_found() {
  local env_var=$1 candidate
  shift
  for candidate in "$@"; do
    if _shell_has_command "$candidate"; then
      export "$env_var=$candidate"
      return 0
    fi
  done
  return 1
}

__set_if_found EDITOR nvim vim vi nano pico
__set_if_found BROWSER links lynx w3m
__set_if_found PAGER bat batcat less more
[[ -v BAT_PAGER ]] || { __set_if_found BAT_PAGER less more || export BAT_PAGER=''; }
unset -f __set_if_found
