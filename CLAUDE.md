# Project Structure

macOS / Linux / WSL 対応のdotfiles管理リポジトリ。`install.sh`がエントリーポイント。

## ディレクトリ・ファイル構成

| パス | 説明 |
|------|------|
| `install.sh` | セットアップスクリプト。OS検出→パッケージインストール→dotfileシンボリックリンク作成を行う |
| `Brewfile` | macOS用Homebrewパッケージ定義（CLI/cask両方） |
| `.shell_common` | bash/zsh共通のシェル設定（エイリアス、色設定、Homebrew初期化等） |
| `.config/` | XDG準拠アプリの設定ディレクトリ（gh, git, raycast） |
| `.devcontainer/` | VSCode DevContainer / GitHub Codespaces用の構成 |
| `.github/` | GitHub Actions CI ワークフロー定義 |
| `.claude/` | Claude Code のプロジェクト設定（シンボリックリンク対象外） |

## 仕組み

- `install.sh` はリポジトリ直下の `.??*` パターンのファイル/ディレクトリを `$HOME` にシンボリックリンクする（`.git`, `.github`, `.devcontainer`, `.claude` は除外）
- macOSでは `Brewfile` 経由で `brew bundle` を実行、Linux/WSLでは `apt-get` + fzfソースビルド
- CI環境（`CI=true`）ではcaskアプリのインストールをスキップ
