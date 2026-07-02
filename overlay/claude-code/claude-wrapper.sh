#!/usr/bin/env bash

export PATH="@claude-code-dir@${PATH:+:$PATH}"

if [ $# -eq 0 ] && [ "@use-sandbox@" = "1" ]; then
  target="@sandbox@"
else
  target="@claude-code-dir@/claude"
fi

if [ -n "$CLAUDE_CONFIG_DIR" ]; then
  exec "$target" "$@"
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PROFILE_DIR="$CONFIG_DIR/profile-claude-code"
CURRENT_FILE="$PROFILE_DIR/current"
PROFILES_FILE="$PROFILE_DIR/profiles.conf"

if [ -f "$CURRENT_FILE" ]; then
  current_profile=$(cat "$CURRENT_FILE")
fi

if [ -z "$current_profile" ]; then
  exec "$target" "$@"
fi

if [ -f "$PROFILES_FILE" ]; then
  profile_path=$(grep "^${current_profile}|" "$PROFILES_FILE" | head -n1 | cut -d'|' -f2)
fi

if [ -z "$profile_path" ]; then
  exec "$target" "$@"
fi

if [ ! -d "$profile_path" ]; then
  exec "$target" "$@"
fi

export CLAUDE_CONFIG_DIR="$profile_path"
exec "$target" "$@"
