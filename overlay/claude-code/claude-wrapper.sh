#!/usr/bin/env bash

# Thin wrapper that sets CLAUDE_CONFIG_DIR based on active profile
# and passes all arguments through to the real claude binary.

# Respect existing CLAUDE_CONFIG_DIR if set
if [ -n "$CLAUDE_CONFIG_DIR" ]; then
  exec @claude-code@ "$@"
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
  exec @claude-code@ "$@"
fi

# Look up profile path from profiles.conf
if [ -f "$PROFILES_FILE" ]; then
  profile_path=$(grep "^${current_profile}|" "$PROFILES_FILE" | head -n1 | cut -d'|' -f2)
fi

# If profile not found in conf, fall back to default
if [ -z "$profile_path" ]; then
  exec @claude-code@ "$@"
fi

# If profile directory doesn't exist, fall back to default
if [ ! -d "$profile_path" ]; then
  exec @claude-code@ "$@"
fi

export CLAUDE_CONFIG_DIR="$profile_path"
exec @claude-code@ "$@"
