#!/usr/bin/env bash

# Thin wrapper that sets CLAUDE_CONFIG_DIR based on active profile.
# Routes to sandbox (sandboxed) when no args, or to real claude when args are given.

# Ensure the real claude binary is in PATH
export PATH="@claude-code-dir@${PATH:+:$PATH}"

# Determine target: no args → sandbox (sandboxed), with args → real claude
if [ $# -eq 0 ]; then
  target="@sandbox@"
else
  target="@claude-code-dir@/claude"
fi

# Respect existing CLAUDE_CONFIG_DIR if set
if [ -n "$CLAUDE_CONFIG_DIR" ]; then
  exec "$target" "$@"
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PROFILE_DIR="$CONFIG_DIR/profile-claude-code"
CURRENT_FILE="$PROFILE_DIR/current"
PROFILES_FILE="$PROFILE_DIR/profiles.conf"

# Read current profile name
if [ -f "$CURRENT_FILE" ]; then
  current_profile=$(cat "$CURRENT_FILE")
fi

# If no current profile or it's empty, use default (no CLAUDE_CONFIG_DIR)
if [ -z "$current_profile" ]; then
  exec "$target" "$@"
fi

# Look up profile path from profiles.conf
if [ -f "$PROFILES_FILE" ]; then
  profile_path=$(grep "^${current_profile}|" "$PROFILES_FILE" | head -n1 | cut -d'|' -f2)
fi

# If profile not found in conf, fall back to default
if [ -z "$profile_path" ]; then
  exec "$target" "$@"
fi

# If profile directory doesn't exist, fall back to default
if [ ! -d "$profile_path" ]; then
  exec "$target" "$@"
fi

export CLAUDE_CONFIG_DIR="$profile_path"
exec "$target" "$@"
