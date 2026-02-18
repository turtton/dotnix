#!/usr/bin/env bash

# Wrapper that fetches the latest claude-code from github:ryoppippi/claude-code-overlay
# at runtime and routes it through sandbox (sandboxed) or directly.

set -euo pipefail

OVERLAY_FLAKE="github:ryoppippi/claude-code-overlay"

# Build latest claude-code and get store path
claude_code_store=$(NIXPKGS_ALLOW_UNFREE=1 nix build --no-link --print-out-paths --impure "$OVERLAY_FLAKE" 2>/dev/null)
if [ -z "$claude_code_store" ] || [ ! -d "$claude_code_store/bin" ]; then
  echo "Error: Failed to build claude-code from $OVERLAY_FLAKE" >&2
  exit 1
fi

# Ensure the real claude binary is in PATH
export PATH="${claude_code_store}/bin${PATH:+:$PATH}"

# Determine target: no args → sandbox (sandboxed), with args → real claude
if [ $# -eq 0 ]; then
  export CLAUDE_CODE_BIN="${claude_code_store}/bin/claude"
  target="@sandbox@"
else
  target="${claude_code_store}/bin/claude"
fi

# Respect existing CLAUDE_CONFIG_DIR if set
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
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
if [ -z "${current_profile:-}" ]; then
  exec "$target" "$@"
fi

# Look up profile path from profiles.conf
if [ -f "$PROFILES_FILE" ]; then
  profile_path=$(grep "^${current_profile}|" "$PROFILES_FILE" | head -n1 | cut -d'|' -f2)
fi

# If profile not found in conf, fall back to default
if [ -z "${profile_path:-}" ]; then
  exec "$target" "$@"
fi

# If profile directory doesn't exist, fall back to default
if [ ! -d "$profile_path" ]; then
  exec "$target" "$@"
fi

export CLAUDE_CONFIG_DIR="$profile_path"
exec "$target" "$@"
