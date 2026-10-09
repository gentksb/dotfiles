#!/usr/bin/env bash
#
# git-sync-sessionstart.sh — Claude Code SessionStart hook。
#
# 「起動時にリモートを正とする」を実現する:
#   - 安全な場合 (clean かつ ahead==0 かつ behind>0) のみ自動 fast-forward。
#   - それ以外 (分岐 / dirty / 未publish) は変更せず additionalContext で通知し /git-sync を促す。
#
# 出力は SessionStart 用 JSON。systemMessage で結果をユーザーに表示する。
# git リポジトリ外と detached HEAD では無出力で exit 0。
set -uo pipefail

emit() {
  # $1 をユーザー向け systemMessage として出力する。
  # $2 が "context" のときは同じ文面をモデル向け additionalContext にも載せる。
  local msg="$1" with_context="${2:-}"
  if command -v jq >/dev/null 2>&1; then
    if [ "$with_context" = "context" ]; then
      jq -n --arg m "$msg" \
        '{systemMessage:$m,hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
    else
      jq -n --arg m "$msg" '{systemMessage:$m}'
    fi
  else
    msg="${msg//\\/\\\\}"; msg="${msg//\"/\\\"}"; msg="${msg//$'\n'/\\n}"
    if [ "$with_context" = "context" ]; then
      printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg" "$msg"
    else
      printf '{"systemMessage":"%s"}\n' "$msg"
    fi
  fi
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
branch="$(git symbolic-ref --short -q HEAD || true)"
[ -z "$branch" ] && exit 0

# upstream 無し → publish を案内
if ! upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
  emit "git: ブランチ '$branch' は upstream 未設定（未publish）。リモートへ反映するには /git-sync を実行。" context
  exit 0
fi
remote="${upstream%%/*}"

if ! git fetch --prune "$remote" >/dev/null 2>&1; then
  emit "git: '$remote' の fetch に失敗。リモートとの同期状態は未確認。" context
  exit 0
fi

counts="$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null || echo "0	0")"
behind="$(printf '%s' "$counts" | awk '{print $1}')"
ahead="$(printf '%s' "$counts" | awk '{print $2}')"
dirty="false"; [ -n "$(git status --porcelain)" ] && dirty="true"

# 安全時のみ自動 fast-forward
if [ "$behind" -gt 0 ] && [ "$ahead" -eq 0 ] && [ "$dirty" = "false" ]; then
  if git merge --ff-only "$upstream" >/dev/null 2>&1; then
    emit "git: リモート $upstream から $behind 件を自動 fast-forward。ローカル '$branch' はリモートと一致。" context
    exit 0
  fi
fi

# 取り込みが必要だが自動FF不可（分岐 / dirty）
if [ "$behind" -gt 0 ]; then
  emit "git: '$branch' はリモートに対し behind=$behind ahead=$ahead dirty=${dirty}。リモートに未取得の変更あり。作業前に /git-sync で rebase 取り込みを推奨。" context
  exit 0
fi

# behind なしだが未push あり
if [ "$ahead" -gt 0 ]; then
  emit "git: '$branch' に未push $ahead 件。必要なら /git-sync で push。" context
  exit 0
fi

emit "git: '$branch' は $upstream と一致。"
exit 0
