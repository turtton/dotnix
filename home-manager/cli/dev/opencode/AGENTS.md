# Language

Answer in 日本語

# 作業方針

- agentが作業に失敗した場合は再度依頼すること（session_idを使って再開）
- 完了までに時間のかかるコマンドをバックグラウンド実行した時は、監視用のスクリプトを実行して完了を待つこと

# ユーザーへの問いかけ

- 不明点がある場合は積極的に質問して確認すること
- ユーザーに話しかける際は必ず `question` tool を使用すること
- question toolを使用する前に、概要については説明しておくこと

# Context Management

- 長時間の作業でも中断・省略しないこと。つらくなったらagentに任せること

# CLI

- `python` → `uv` を使用すること
- 未インストールのコマンド → nixパッケージがあれば `,` を活用すること（例: `, jq`）

# GIT

- GitHubリポジトリへの push / pull は ssh ではなく gh の auth token を活用して行うこと

# End of Work

- 作業完了時は `skill(name="final-review")` を実行
- **ユーザーに報告する際は必ず `question` tool を使用すること**
  なお、文章が多いとUI上見づらくなるため、内容はquestion toolを利用する前に説明し、質問自体は簡潔にすること
