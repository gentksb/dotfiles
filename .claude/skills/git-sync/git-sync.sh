#!/usr/bin/env bash
#
# git-sync.sh — VSCode の Git「Sync」ボタン相当を CLI で再現するスクリプト。
#
# 戦略: fetch --prune → (behind があれば) pull --rebase --autostash → push。
# グローバル git 設定 (pull.rebase 等) には依存せず、挙動はすべてフラグで明示する。
#
# 出力は人間/Claude が読む構造化テキスト。終了コード:
#   0  = 同期成功（または既に同期済み / publish 済み）
#   3  = rebase コンフリクトで中断中（手動解決 or abort が必要）
#   1  = それ以外のエラー
set -uo pipefail

say() { printf '%s\n' "$*"; }

# 1. work tree 判定
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  say "ここは git リポジトリではありません。git-sync は何もしません。"
  exit 0
fi

# 2. 現在ブランチ（detached HEAD は対象外）
branch="$(git symbolic-ref --short -q HEAD || true)"
if [ -z "$branch" ]; then
  say "detached HEAD 状態です。ブランチを checkout してから再実行してください。"
  exit 1
fi

# 3. upstream 解決（無ければ publish = VSCode "Publish Branch" 相当）
if ! upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
  say "ブランチ '$branch' に upstream がありません。origin へ publish します。"
  if git push -u origin "$branch"; then
    say "SUMMARY: branch=$branch action=published upstream=origin/$branch"
    exit 0
  else
    say "publish に失敗しました（push -u origin ${branch}）。"
    exit 1
  fi
fi
remote="${upstream%%/*}"

# 4. fetch
if ! git fetch --prune "$remote" >/dev/null 2>&1; then
  say "git fetch に失敗しました（remote=${remote}）。ネットワーク/認証を確認してください。"
  exit 1
fi

# 5. ahead/behind 算出（left=behind, right=ahead）
counts="$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null || echo "0	0")"
behind="$(printf '%s' "$counts" | awk '{print $1}')"
ahead="$(printf '%s' "$counts" | awk '{print $2}')"

# 6. dirty 判定
dirty="false"
if [ -n "$(git status --porcelain)" ]; then dirty="true"; fi

say "現在: branch=$branch upstream=$upstream behind=$behind ahead=$ahead dirty=$dirty"

# 7. 分岐
if [ "$behind" -eq 0 ] && [ "$ahead" -eq 0 ]; then
  say "SUMMARY: branch=$branch action=up-to-date behind=0 ahead=0"
  exit 0
fi

if [ "$behind" -eq 0 ] && [ "$ahead" -gt 0 ]; then
  say "リモートに未push の $ahead 件を push します。"
  if git push; then
    say "SUMMARY: branch=$branch action=pushed pushed=$ahead"
    exit 0
  else
    say "push に失敗しました。"
    exit 1
  fi
fi

# behind > 0 : リモート差分を rebase で取り込み（autostash で未コミット変更を退避→復元）
say "リモートに $behind 件の差分。pull --rebase --autostash で取り込みます。"
if git pull --rebase --autostash; then
  # rebase 後の ahead を再計算して push 判定
  counts2="$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null || echo "0	0")"
  ahead2="$(printf '%s' "$counts2" | awk '{print $2}')"
  if [ "$ahead2" -gt 0 ]; then
    say "ローカル作業を $behind 件のリモート上に載せ替えました。未push $ahead2 件を push します。"
    if git push; then
      say "SUMMARY: branch=$branch action=rebased+pushed rebased=$behind pushed=$ahead2"
      exit 0
    else
      say "rebase は成功しましたが push に失敗しました。再実行してください。"
      exit 1
    fi
  else
    say "SUMMARY: branch=$branch action=rebased rebased=$behind pushed=0"
    exit 0
  fi
else
  # rebase 進行中＝コンフリクトの可能性
  if [ -d "$(git rev-parse --git-path rebase-merge 2>/dev/null)" ] || \
     [ -d "$(git rev-parse --git-path rebase-apply 2>/dev/null)" ]; then
    conflicts="$(git diff --name-only --diff-filter=U)"
    say "コンフリクトで rebase が中断しました。衝突ファイル:"
    say "$conflicts"
    say "SUMMARY: branch=$branch action=conflict state=rebase-in-progress"
    exit 3
  fi
  say "pull --rebase に失敗しました（コンフリクト以外）。"
  exit 1
fi
