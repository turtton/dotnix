#!/usr/bin/env bash

set -euo pipefail

OVERLAY_FLAKE="github:ryoppippi/claude-code-overlay"

claude_code_store=$(NIXPKGS_ALLOW_UNFREE=1 nix build --no-link --print-out-paths --impure "$OVERLAY_FLAKE" 2>/dev/null)
if [ -z "$claude_code_store" ] || [ ! -d "$claude_code_store/bin" ]; then
  echo "Error: Failed to build claude-code from $OVERLAY_FLAKE" >&2
  exit 1
fi

sandbox_path="@sandbox-path@"
export PATH="${claude_code_store}/bin${sandbox_path:+:$sandbox_path}${PATH:+:$PATH}"

target="${claude_code_store}/bin/claude"

if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
  exec "$target" "$@"
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PROFILE_DIR="$CONFIG_DIR/profile-claude-code"
CURRENT_FILE="$PROFILE_DIR/current"
PROFILES_FILE="$PROFILE_DIR/profiles.conf"

if [ -f "$CURRENT_FILE" ]; then
  current_profile=$(cat "$CURRENT_FILE")
fi

if [ -z "${current_profile:-}" ]; then
  exec "$target" "$@"
fi

if [ -f "$PROFILES_FILE" ]; then
  profile_path=$(grep "^${current_profile}|" "$PROFILES_FILE" | head -n1 | cut -d'|' -f2)
fi

if [ -z "${profile_path:-}" ]; then
  exec "$target" "$@"
fi

if [ ! -d "$profile_path" ]; then
  exec "$target" "$@"
fi

export CLAUDE_CONFIG_DIR="$profile_path"
exec "$target" "$@"
