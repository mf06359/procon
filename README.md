# Competitive-programming C++ environment (`import std;`)

Compile and run C++ that uses `import std;`, using GCC 15 provided by Nix.
`g++ XXX.cpp` compiles it and produces the executable `./XXX`.

```sh
g++ a.cpp     # -> ./a
./a           # run
```

---

## From scratch

### 0. Install Nix (once per machine)

```sh
# Determinate Nix installer (flakes etc. enabled)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

> Official installer also works: `sh <(curl -L https://nixos.org/nix/install)`

Reopen the terminal, then verify:

```sh
nix-shell --version
```

### 1. Go to this directory

```sh
cd path/to/procon      # where shell.nix is
```

### 2. Enter the environment

Pick a shell with a tag (`-A`). Bare `nix-shell` defaults to bash.

```sh
nix-shell              # bash (default)
nix-shell -A bash      # bash
nix-shell -A zsh       # zsh (sources your ~/.zshrc, then unaliases g++)
nix-shell -A nushell   # nushell
```

- First run fetches GCC 15 (and the chosen shell) from cache (~72 MiB download, no source build).
- Later runs are instant. Exit with `exit` or `Ctrl-D`.

### 3. Compile and run

```sh
g++ a.cpp        # compile (import std;) -> ./a
./a              # run
```

- Output name follows the source: **`XXX.cpp` -> `./XXX`** (e.g. `foo.cpp` -> `./foo`).
- Extra flags pass through: `g++ a.cpp -DLOCAL -o foo`.
- Stdin in bash/zsh: `./a < input.txt`. In nushell use a pipe:
  ```nu
  open --raw input.txt | ./a
  "1\n" | ./a
  ```
- The first compile builds the std module into `~/.cache/cp-cxx` (a few seconds); reused afterwards.
- Nothing is written to the working directory (no `gcm.cache/`): `import std;` is resolved from the cache via `-fmodule-mapper`.

## Console appearance

Each shell uses a Kali-style two-line starship prompt that ends with `cp:<shell>`, so you can
tell you are inside the env:

```text
┌──(user@host)-[~/path]-[git]-(cp:bash)
└─$
```

The look is defined in `./.config/`:

- `.config/starship.toml` — the theme (edit this for the prompt look).
- `.config/bash.sh`, `.config/zsh.zsh`, `.config/nu.nu` — per-shell enablement / tweaks.

`shell.nix` sets `STARSHIP_CONFIG` to `.config/starship.toml` and loads the matching file per shell.
Requires `starship` on `PATH` (skipped gracefully if missing).

## Bug detection

`g++` always compiles with:

- **Compile-time warnings**: `-Wall -Wextra -Wshadow` (`-Wno-sign-compare`) — catches unused
  variables, bad shifts, uninitialized use, etc.
- **Runtime bounds checks**: `-D_GLIBCXX_ASSERTIONS` — e.g. `vector::operator[]` out of range
  aborts with an assertion message.

`-fsanitize=address,undefined` is intentionally **not** used: nix GCC on macOS ships no
`libasan`/`libubsan`, so it cannot link. `_GLIBCXX_ASSERTIONS` covers the common out-of-bounds
case. For full ASan/UBSan, compile the file with clang (without `import std;`).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `nix-shell: command not found` | Nix not installed, or terminal not reopened after install |
| `std.cc not found` warning | That GCC lacks import std; (shell.nix uses GCC 15, so it should not happen) |
| `g++` runs the wrong compiler in zsh | The zsh tag unaliases `g++`; check `which g++` points to `/nix/store/...-g++/bin/g++` |
| Move to another machine | Copy `shell.nix` and run `nix-shell` (needs network on first run) |
| Want nushell instead of bash | `nix-shell -A nushell` |
| Plain prompt (no `cp:` look) | Install `starship`, or edit/empty `.config/{bash.sh,zsh.zsh,nu.nu}` |
