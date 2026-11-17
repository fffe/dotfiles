() {
  local blue=${_DOTFILES_COLORS[blue]} blue_sgr=${_DOTFILES_COLORS[blue_sgr]}
  local coral=${_DOTFILES_COLORS[coral]}
  local selection=${_DOTFILES_COLORS[selection]} menu=${_DOTFILES_COLORS[menu]}
  zle_highlight=("${(@)zle_highlight:#region:*}" "region:$selection")
  zstyle ':completion:*:default' list-colors \
    'no=0' 'fi=0' 'tc=0' 'sp=0' 'ec=\e[0m' \
    "${(@s.:.)LS_COLORS}" "sa=0;$blue_sgr" "ma=$menu"
  zstyle ':completion:*:processes' list-colors "=(#b) #([0-9]#)*=0=0;$blue_sgr" "ma=$menu"
  zstyle ':completion:*:descriptions' format $'\n'"%F{$blue}%d:%f"
  zstyle ':completion:*:warnings' format "%F{$coral}No match.%f"
  zstyle ':completion:*:corrections' format "%F{$blue}Match: %d (errors: %e)%f"
}
