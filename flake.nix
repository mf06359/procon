{
  description = "Competitive-programming C++ environment (import std; / GCC 15)";

  # Pinned nixpkgs -> identical gcc15 on any machine. To update:
  #   nix flake update            (or: nix flake lock --update-input nixpkgs)
  # and optionally change the rev below.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/9eac87a12312b8f60dd52e1c6e1a265f6fc7f5fc";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # nix develop            -> zsh (default)
      # nix develop .#bash     -> bash
      # nix develop .#zsh      -> zsh
      # nix develop .#nushell  -> nushell
      #
      #   g++ a.cpp   # compile (import std;) -> ./a
      #   ./a         # run
      #
      # Run from the repo root: ./.config and ./ac-library are read live from $PWD
      # (so the flake itself references no local files — only flake.nix is needed
      # in git for `nix develop` to work).
      devShells = forAllSystems (pkgs:
        let
          gcc = pkgs.gcc15; # required for import std; (GCC 15+)

          # PATH wrapper for g++: one source file -> executable named after it
          # (a.cpp -> ./a). -Wall/-Wextra/-Wshadow catch obvious bugs at compile
          # time; -D_GLIBCXX_ASSERTIONS adds runtime bounds checks. -fsanitize is
          # NOT used: nix GCC on macOS ships no libasan/libubsan.
          cpGxx = pkgs.writeShellScriptBin "g++" ''
            REAL_GXX="${gcc}/bin/g++"                 # real g++ (absolute -> no recursion)
            ATCODER="''${CP_ATCODER_DIR:-}"           # set by the devShell to $PWD/ac-library
            CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/cp-cxx"   # global std module cache
            STD_GCM="$CACHE/std.gcm"; STD_O="$CACHE/std.o"; STD_MAP="$CACHE/std.map"
            # -fmodule-mapper points `import std;` at the cached BMI -> no gcm.cache/
            # is created in the working directory.
            FLAGS=(-std=c++23 -fmodules -fmodule-mapper="$STD_MAP" -O2
                   -Wall -Wextra -Wshadow -Wno-sign-compare -D_GLIBCXX_ASSERTIONS)
            [ -n "$ATCODER" ] && [ -d "$ATCODER" ] && FLAGS+=(-isystem "$ATCODER")

            # locate libstdc++'s std.cc shipped with this gcc
            find_std_cc() {
              local d cand
              for d in $("$REAL_GXX" -std=c++23 -E -x c++ /dev/null -Wp,-v 2>&1 | sed -n 's/^ //p'); do
                for cand in "$d/std.cc" "$d/bits/std.cc"; do
                  [ -f "$cand" ] && { printf '%s\n' "$cand"; return 0; }
                done
              done
              return 1
            }

            # build the std module once into the cache; rebuild if gcc or FLAGS change
            ensure_global_std() {
              local src want have
              src="$(find_std_cc)" || { echo "std.cc not found (import std; unsupported?)" >&2; return 1; }
              mkdir -p "$CACHE"
              printf 'std %s\n' "$STD_GCM" > "$STD_MAP"
              want="''${FLAGS[*]}"
              have="$(cat "$CACHE/build-flags" 2>/dev/null || true)"
              if [ ! -f "$STD_GCM" ] || [ "$src" -nt "$STD_GCM" ] || [ "$want" != "$have" ]; then
                echo "building std module (first run / flags changed)..." >&2
                "$REAL_GXX" "''${FLAGS[@]}" -c "$src" -o "$STD_O" || return 1
                printf '%s' "$want" > "$CACHE/build-flags"
              fi
            }

            # split args into one source file and the rest
            src=""; have_o=0; rest=()
            for a in "$@"; do
              case "$a" in
                -o) have_o=1; rest+=("$a") ;;
                *.cpp|*.cc|*.cxx|*.C|*.c++)
                  if [ -z "$src" ]; then src="$a"; else rest+=("$a"); fi ;;
                *) rest+=("$a") ;;
              esac
            done

            # no source (e.g. g++ --version) -> delegate to real g++
            if [ -z "$src" ]; then exec "$REAL_GXX" "$@"; fi

            ensure_global_std || exit 1
            if [ "$have_o" -eq 1 ]; then
              exec "$REAL_GXX" "''${FLAGS[@]}" "$src" "$STD_O" "''${rest[@]}"
            else
              out="''${src##*/}"; out="''${out%.*}"
              "$REAL_GXX" "''${FLAGS[@]}" "$src" "$STD_O" -o "$out" "''${rest[@]}" && echo "-> ./$out"
            fi
          '';

          # one devShell per interactive shell; `launch` runs only for interactive sessions
          mkShellFor = { tag, extraPkgs ? [ ], launch ? "" }:
            pkgs.mkShell {
              packages = [ cpGxx gcc pkgs.starship ]   # starship provided by nix (system-independent)
                ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.wl-clipboard pkgs.xclip ]
                ++ extraPkgs;
              shellHook = ''
                export CP_GXX_BIN="${cpGxx}/bin"
                export PATH="$CP_GXX_BIN:$PATH"   # our g++ wins over any other g++
                # project files are read live from the dir you ran `nix develop` in
                export CP_ATCODER_DIR="$PWD/ac-library"
                export CP_CONFIG_DIR="$PWD/.config"
                export CP_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/cp-cxx"
                export STARSHIP_CONFIG="$CP_CONFIG_DIR/starship.toml"
                [ -d "$CP_ATCODER_DIR" ] && export CPLUS_INCLUDE_PATH="$CP_ATCODER_DIR''${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"
                if [[ $- == *i* ]]; then
                  echo "C++ CP env (${tag} / import std; / gcc15) — g++ XXX.cpp -> ./XXX"
                  ${launch}
                fi
              '';
            };

          nushell = mkShellFor {
            tag = "nushell";
            extraPkgs = [ pkgs.nushell ];
            launch = ''
              if command -v starship >/dev/null 2>&1; then
                mkdir -p "$CP_CACHE_DIR"
                starship init nu > "$CP_CACHE_DIR/starship.nu" 2>/dev/null || true
                exec nu --execute "source $CP_CACHE_DIR/starship.nu; source $CP_CONFIG_DIR/nu.nu"
              else
                exec nu --execute "source $CP_CONFIG_DIR/nu.nu"
              fi
            '';
          };
          bash = mkShellFor {
            tag = "bash";
            launch = ''[ -f "$CP_CONFIG_DIR/bash.sh" ] && source "$CP_CONFIG_DIR/bash.sh"'';
          };
          zsh = mkShellFor {
            tag = "zsh";
            extraPkgs = [ pkgs.zsh ];
            # source the user's config, drop their `alias g++`, re-prioritise ours, set prompt
            launch = ''
              ZD="$(mktemp -d)"
              {
                printf '%s\n' '[ -f "$HOME/.zshenv" ] && source "$HOME/.zshenv"'
                printf '%s\n' '[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc"'
                printf '%s\n' 'unalias g++ 2>/dev/null; unfunction g++ 2>/dev/null'
                printf '%s\n' 'export PATH="'"$CP_GXX_BIN"':$PATH"'
                printf '%s\n' '[ -f "'"$CP_CONFIG_DIR"'/zsh.zsh" ] && source "'"$CP_CONFIG_DIR"'/zsh.zsh"'
              } > "$ZD/.zshrc"
              export ZDOTDIR="$ZD"
              exec zsh -i
            '';
          };
        in
        {
          default = zsh;
          inherit bash zsh nushell;
        });
    };
}
