#!/usr/bin/env bash
#
# git-sync-stop.sh — Claude Code Stop hook。
#
# push 漏れ防止: 未push コミットがあれば「セッション中 1 回だけ」警告する。
# session_id ごとの sentinel で毎ターンの騒音と無限ループを抑止する。
#
# 入力: stdin に Stop hook の JSON（session_id を含む）。
# 出力: 警告時のみ Stop 用 additionalContext JSON。それ以外は無出力 exit 0。
set -uo pipefail

input="$(cat 2>/dev/null || true)"

session_id=""
if command -v jq >/dev/null 2>&1; then
  session_id="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
fi
[ -z "$session_id" ] && session_id="unknown"

sentinel="${TMPDIR:-/tmp}/claude-git-sync-pushwarn-${session_id}"
[ -f "$sentinel" ] && exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
branch="$(git symbolic-ref --short -q HEAD || true)"
[ -z "$branch" ] && exit 0
upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
[ -z "$upstream" ] && exit 0

counts="$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null || echo "0	0")"
ahead="$(printf '%s' "$counts" | awk '{print $2}')"

if [ "${ahead:-0}" -gt 0 ]; then
  : > "$sentinel"
  ctx="git: '$branch' に未push $ahead 件。終了前に /git-sync を推奨（Sync漏れ防止）。"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg c "$ctx" \
      '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:$c}}'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}\n' "$ctx"
  fi
fi
exit 0
