---
name: git-sync
description: ローカルとリモートを同期する（fetch → rebase + autostash → push）。VSCode の Git「Sync」ボタン相当。リモートを正としてローカルの未push作業を rebase で載せ替える。
disable-model-invocation: true
allowed-tools: Bash
---

# git-sync — VSCode の Git Sync ボタン相当

リモートを正として、ローカルの作業を取り込み・反映する。手動トリガ専用（`/git-sync`）。

## 手順

1. 次のスクリプトを実行する:

   ```
   bash "${CLAUDE_SKILL_DIR}/git-sync.sh"
   ```

2. 出力末尾の `SUMMARY:` 行と本文を読み、ゲンへ**日本語で簡潔に**結果を報告する
   （何件 rebase / push したか、autostash の復元有無、publish したか等）。

## コンフリクト時（終了コード 3 / `action=conflict`）

rebase が中断状態のまま停止している。ゲンに次の2択を提示し、選択を仰ぐこと:

- **(a) その場で解決**: 衝突ファイルを編集して解決 → `git add <files>` → `git rebase --continue`。
  解決後、ahead があれば `git push` まで行う。CLI/エージェントの利点を活かしターミナルに戻らず解決できる。
- **(b) 中止して復帰**: `git rebase --abort` で同期前の状態へ完全復帰（autostash も元に戻る）。

勝手にどちらかを実行せず、必ず確認する。

## 注意

- `disable-model-invocation: true` のため Claude が自動起動することはない。ゲンが `/git-sync` を打ったときだけ動く。
- グローバル git 設定には依存しない（pull.rebase 等が未設定でも rebase で動く）。
