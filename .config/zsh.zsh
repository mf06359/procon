# zsh console appearance + tools for the CP nix-shell.
# Enables starship (themed by .config/starship.toml via $STARSHIP_CONFIG).
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
# Your ~/.zshrc may also init starship; dedupe the hooks so it runs once.
typeset -gU precmd_functions preexec_functions

# History search (Ctrl+R via fzf) and the faint inline autosuggestions come from
# your own ~/.zshrc (fzf key-bindings + zsh-autosuggestions), which this shell
# sources. History persists via the HISTFILE set there (~/.zsh_history).

# clip: copy stdin to the system clipboard.
# mac -> pbcopy; Linux(Wayland) -> wl-copy; Linux(X11) -> xclip/xsel.
if command -v pbcopy >/dev/null 2>&1; then
  alias clip='pbcopy'
elif command -v wl-copy >/dev/null 2>&1; then
  alias clip='wl-copy'
elif command -v xclip >/dev/null 2>&1; then
  alias clip='xclip -selection clipboard'
elif command -v xsel >/dev/null 2>&1; then
  alias clip='xsel --clipboard --input'
fi
