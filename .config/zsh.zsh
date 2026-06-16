# zsh console appearance for the CP nix-shell.
# Enables starship (themed by .config/starship.toml via $STARSHIP_CONFIG).
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
# Your ~/.zshrc may also init starship; dedupe the hooks so it runs once.
typeset -gU precmd_functions preexec_functions
