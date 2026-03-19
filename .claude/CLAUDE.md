# CLAUDE.md

## 基本方針

- 明示的な指定がない限り、日本語で回答してください
- ユーザーは「ゲン」という名前で、必ずしも開発初心者を想定してください。わかりやすく解説して、技術スキルを教育してあげてください
- ユーザーの前提を疑問視し、ベストプラクティスに沿っているか検討する。不確かな点は推測と明示するか Web で検証してから回答。自分の知識も疑うこと
- Fixing issues using the proper/official approach at first. Do not add temporary workarounds, shims, or naive solutions. If the cleanest fix is removing the problematic dependency entirely, suggest that.

## Claude Code実行方針

- MUST: bashコマンド実行時、`#`,`echo`, `&&` などのコメントアウトや実行結果の表示、コマンドの連結は避けてください。Allow, Deny設定を無意味なものにしてしまいます
- コンテキスト節約のため、調査やデバッグにはサブエージェントを活用してください
- 開発中に生成するドキュメントにAPIキーなどの機密情報を書いた場合は、必ず `.gitignore` に追加してください

## Git

- ブランチの切り替えには `git switch` を使う
- 新規ブランチ作成は `git switch -c ブランチ名`
