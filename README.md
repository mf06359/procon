# 競技プログラミング C++ 環境（`import std;` 対応）

`import std;` を使った C++ を、Nix で用意した **GCC 15** でコンパイル・実行するための環境です。
`g++ XXX.cpp` を実行すると、`import std;` 込みでコンパイルして実行ファイル `./XXX` を生成します。

```sh
g++ a.cpp     # → ./a を生成
./a           # 実行
```

---

## 0 から実行する手順

### 手順 0. Nix をインストール（このPCに初めて入れるとき・1回だけ）

新しいPCでは、まず Nix を入れます（macOS / Linux 共通）。

```sh
# Determinate Nix インストーラ（flakes 等が有効な状態で入る・推奨）
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

> 公式インストーラでも可: `sh <(curl -L https://nixos.org/nix/install)`

インストール後は **ターミナルを開き直す**（または表示される指示に従って source する）と `nix-shell` が使えます。確認:

```sh
nix-shell --version
```

すでに Nix が入っているなら、この手順は不要です。

### 手順 1. このディレクトリに移動

`shell.nix` のあるディレクトリに移動するだけです（git リポジトリである必要はありません）。

```sh
cd ~/procon      # shell.nix がある場所
```

### 手順 2. 環境に入る

```sh
nix-shell
```

- **初回のみ**、固定された GCC 15 一式をキャッシュから取得します（≈72 MiB ダウンロード / 約 1.6 GiB 展開、**ソースビルドはなし**）。
- 2 回目以降は一瞬で入れます。
- 抜けるときは `exit` または `Ctrl-D`。

### 手順 3. コンパイルして実行

`nix-shell` に入った状態で:

```sh
g++ a.cpp        # import std; 込みでコンパイル → ./a を生成
./a              # 実行
```

- 出力名はソース名から決まります: **`XXX.cpp` → `./XXX`**（例: `foo.cpp` → `./foo`）。
- 標準入力を読むプログラムは通常どおり: `./a < input.txt` や `echo "1" | ./a`。
- 初回コンパイル時だけ std モジュール（`std.gcm` / `std.o`）を 1 回ビルドして `~/.cache/cp-cxx` にキャッシュします（数秒）。以降は再利用されます。

#### ワンライナー（入る → ビルド → 実行）

```sh
nix-shell --run 'g++ a.cpp && ./a'
```

---

## 詳細

### コンパイルオプション

デフォルトは `-std=c++23 -fmodules -O2 -Wall -Wextra`（`shell.nix` の `CP_CXX_FLAGS` で変更可）。
追加フラグはそのまま渡せます（例: 自作ライブラリの include）:

```sh
g++ a.cpp -Ilib/include
```

- `-o 名前` を自分で指定した場合は、その名前が優先されます。
- 対応拡張子: `.cpp` `.cc` `.cxx` `.C` `.c++`。
- ソース以外の使い方（`g++ --version` など）はそのまま素の g++ に委譲されます。

### `import std;` が動く仕組み（参考）

GCC で `import std;` を使うには次の 3 つが必要です。`shell.nix` の `g++` ラッパーがこれを自動化しています。

1. `-fmodules -std=c++23` でコンパイルする
2. libstdc++ の `std.cc` から `std.gcm`（コンパイル済みモジュール）を生成する
3. その `std.o`（モジュール初期化子）をリンクする ← これが無いと `"initializer for module std"` のリンクエラーになる

### 再現性

`shell.nix` は nixpkgs を**特定コミットに固定**しています。そのため別のPC・別の日に実行しても、まったく同じ GCC 15.2.0 になります。
GCC を更新したいときは、`shell.nix` 内の `url` のコミットハッシュを差し替えて sha256 を取り直します:

```sh
nix-prefetch-url --unpack https://github.com/NixOS/nixpkgs/archive/<新しいrev>.tar.gz
```

---

## トラブルシュート

| 症状 | 対処 |
|---|---|
| `nix-shell: command not found` | Nix 未インストール、またはインストール後にターミナルを開き直していない |
| `std.cc が見つかりません` という警告 | その GCC が `import std;` 非対応。`shell.nix` は GCC 15 を使うので通常出ない |
| 別マシンに移したい | `shell.nix` を置いて `nix-shell` するだけ（初回はネット接続が必要） |
