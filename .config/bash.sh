# bash console appearance + tools for the CP nix-shell.

# Enables starship (themed by .config/starship.toml via $STARSHIP_CONFIG).
if command -v starship >/dev/null 2>&1; then
  # ~/.bashrc may have set up another prompt engine (e.g. oh-my-posh) with its own
  # DEBUG trap + PROMPT_COMMAND / bash-preexec hooks. Left in place they override
  # starship, and worse, recurse: starship's $(starship prompt ...) re-fires the
  # DEBUG trap, blowing the stack and segfaulting bash. Detach from all of it, then
  # start starship standalone. (bash.sh is sourced after ~/.bashrc.)
  trap - DEBUG
  unset PROMPT_COMMAND
  unset -f _omp_hook 2>/dev/null
  unset __bp_imported bash_preexec_imported __bp_install_string 2>/dev/null
  precmd_functions=(); preexec_functions=()
  eval "$(starship init bash)"
fi

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
