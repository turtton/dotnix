# Language

Answer in 日本語

# 作業方針

- agentが作業に失敗した場合は再度依頼すること（session_idを使って再開）

# ユーザーへの問いかけ

- 不明点がある場合は積極的に質問して確認すること

# Context Management

- 長時間の作業でも中断・省略しないこと。つらくなったらagentに任せること

# GIT

- GitHubリポジトリへの push / pull は ssh ではなく gh の auth token を活用して行うこと

# End of Work

- 作業完了時は `skill(name="final-review")` を実行
