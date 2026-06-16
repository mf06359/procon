# bash console appearance for the CP nix-shell.
# Enables starship (themed by .config/starship.toml via $STARSHIP_CONFIG).
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
