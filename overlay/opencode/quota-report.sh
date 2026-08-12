#!/usr/bin/env bash
# クォータポーラー共通の herdr metadata レポーター。
# HERDR_SESSION / HERDR_PANE_ID が無い環境 (従来 tmux 経路) では何もせず終了する
set -u

if [[ -z ${HERDR_SESSION:-} || -z ${HERDR_PANE_ID:-} ]]; then
  exit 0
fi

if [[ $# -ne 2 ]]; then
  echo "usage: quota-report.sh <provider> <value>" >&2
  exit 2
fi

provider="$1"
case "$provider" in
copilot | openai | crof | openrouter | claude | kimi) ;;
*)
  echo "quota-report.sh: unknown provider: $provider" >&2
  exit 2
  ;;
esac

value=$(printf '%s' "$2" | LC_ALL=C tr -d '\000-\037\177')
token="${provider}=${value}"
token="${token:0:80}"

output=$(herdr --session "$HERDR_SESSION" pane report-metadata "$HERDR_PANE_ID" \
  --source "quota:$provider" --token "$token" --ttl-ms 200000 2>&1) && exit 0

# pane 消失はポーラーの終了条件なので成功扱い。それ以外の失敗は metadata を捏造せず非ゼロ終了
if grep -q pane_not_found <<<"$output"; then
  exit 0
fi
exit 1
