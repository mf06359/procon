# 競技プログラミング用 C++ 環境 (`import std;` 対応)
#
#   nix-shell        # この shell.nix のあるディレクトリで実行 → 環境に入る
#   g++ a.cpp        # → import std; 込みでコンパイルし、実行ファイル ./a を生成
#   ./a              # 実行
#
# `import std;` には GCC 15 以降が必要なので、gcc15 を固定で取得しています。
{ }:

let
  # gcc15 (import std; 対応) を確実に得るため nixpkgs を「コミット固定」。
  # この rev は nixpkgs-unstable の特定コミットなので、どのPCでも同一の gcc15 になる。
  # 更新したいときは url の hash を新しいコミットに変え、sha256 を取り直す:
  #   nix-prefetch-url --unpack https://github.com/NixOS/nixpkgs/archive/<rev>.tar.gz
  nixpkgs = fetchTarball {
    url    = "https://github.com/NixOS/nixpkgs/archive/9eac87a12312b8f60dd52e1c6e1a265f6fc7f5fc.tar.gz";
    sha256 = "sha256-d2xfDjnfRuf/xYGdu9VVRHiav/2w5hDL/5cw2TuVAXw=";
  };
  pkgs = import nixpkgs { };

  gcc = pkgs.gcc15; # import std; に必要 (GCC 15+)
  atcoderLibrary = ./ac-library; # このリポジトリに同梱されている AtCoder Library
in
pkgs.mkShell {
  packages = [ gcc ];

  # ↓ ここが「~/.zshrc の alias のようなコマンド」本体。
  #   nix-shell に入った時にシェル関数 g++ として定義されます。
  shellHook = ''
    echo "C++ 競プロ環境 (import std; 対応 / gcc15)"

    # 実体の g++ (PATH の曖昧さを避けて store path を直接指す)
    export CP_GXX="${gcc}/bin/g++"
    # AtCoder Library を `#include <atcoder/...>` で引けるようにする
    export CP_ATCODER_DIR="${atcoderLibrary}"
    export CPLUS_INCLUDE_PATH="$CP_ATCODER_DIR''${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"
    # コンパイルフラグ。std モジュールと利用側で同じものを使う必要があるので一元管理。
    CP_CXX_FLAGS=(-std=c++23 -fmodules -O2 -Wall -Wextra -I"$CP_ATCODER_DIR")
    # std モジュール (std.gcm / std.o) のグローバルキャッシュ置き場
    export CP_GCM_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/cp-cxx/gcm.cache"
    export CP_STD_O="$CP_GCM_DIR/std.o"   # リンク時に必要なモジュール初期化子

    # この gcc に同梱されている libstdc++ のモジュールソース std.cc を探す
    # (gcc15/nixpkgs では include/c++/<ver>/bits/std.cc に置かれている)
    CP_STD_SRC=""
    for d in $("$CP_GXX" -std=c++23 -E -x c++ /dev/null -Wp,-v 2>&1 | sed -n 's/^ //p'); do
      for cand in "$d/std.cc" "$d/bits/std.cc"; do
        if [ -f "$cand" ]; then CP_STD_SRC="$cand"; break 2; fi
      done
    done
    export CP_STD_SRC
    if [ -z "$CP_STD_SRC" ]; then
      echo "warning: std.cc が見つかりません (この gcc は import std; 非対応かもしれません)" >&2
    fi

    # std モジュールの CMI(std.gcm) を一度だけビルドしてキャッシュ
    _cp_build_std() {
      [ -n "$CP_STD_SRC" ] || { echo "import std; は利用できません" >&2; return 1; }
      mkdir -p "$CP_GCM_DIR"
      if [ ! -f "$CP_GCM_DIR/std.gcm" ] || [ "$CP_STD_SRC" -nt "$CP_GCM_DIR/std.gcm" ]; then
        echo "std モジュールをビルド中 (初回のみ)..." >&2
        ( cd "$CP_GCM_DIR/.." \
          && "$CP_GXX" "''${CP_CXX_FLAGS[@]}" -c "$CP_STD_SRC" -o "$CP_GCM_DIR/std.o" ) || return 1
      fi
    }

    # g++ ラッパー: ソース1個を渡すと import std; 込みでビルドし、
    #   拡張子を除いた名前 (a.cpp -> a) で実行ファイルを作る。
    #   ソースが無い / 別の使い方 (--version 等) のときは素の g++ にそのまま渡す。
    g++() {
      local src="" out="" have_o=0 a
      local -a rest=()
      for a in "$@"; do
        case "$a" in
          -o) have_o=1; rest+=("$a") ;;
          *.cpp|*.cc|*.cxx|*.C|*.c++)
            if [ -z "$src" ]; then src="$a"; else rest+=("$a"); fi ;;
          *) rest+=("$a") ;;
        esac
      done

      if [ -z "$src" ]; then "$CP_GXX" "$@"; return; fi

      _cp_build_std || return 1
      # import std; のコンパイルに使う std.gcm をこのディレクトリの gcm.cache に用意
      mkdir -p gcm.cache
      if [ ! -f gcm.cache/std.gcm ] || [ "$CP_GCM_DIR/std.gcm" -nt gcm.cache/std.gcm ]; then
        cp "$CP_GCM_DIR/std.gcm" gcm.cache/std.gcm
      fi

      # std.o (モジュール初期化子) はリンク時に必要なので毎回渡す
      if [ "$have_o" -eq 1 ]; then
        "$CP_GXX" "''${CP_CXX_FLAGS[@]}" "$src" "$CP_STD_O" "''${rest[@]}"
      else
        out="''${src##*/}"; out="''${out%.*}"
        "$CP_GXX" "''${CP_CXX_FLAGS[@]}" "$src" "$CP_STD_O" -o "$out" "''${rest[@]}" && echo "-> ./$out"
      fi
    }

    echo "使い方:  g++ XXX.cpp   ->  実行ファイル ./XXX を生成"
  '';
}
