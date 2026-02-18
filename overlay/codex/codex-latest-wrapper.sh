#!/usr/bin/env bash

# Wrapper that fetches the latest codex from github:numtide/llm-agents.nix#codex
# at runtime and executes it directly.

set -euo pipefail

FLAKE_REF="github:numtide/llm-agents.nix#codex"

# Build latest codex and get store path
codex_store=$(nix build --no-link --print-out-paths "$FLAKE_REF" 2>/dev/null)
if [ -z "$codex_store" ] || [ ! -d "$codex_store/bin" ]; then
  echo "Error: Failed to build codex from $FLAKE_REF" >&2
  exit 1
fi

exec "${codex_store}/bin/codex" "$@"
