#!/usr/bin/env bash

# Wrapper that fetches the latest opencode from github:numtide/llm-agents.nix#opencode
# at runtime and executes it directly.

set -euo pipefail

FLAKE_REF="github:numtide/llm-agents.nix#opencode"

# Build latest opencode and get store path
opencode_store=$(nix build --no-link --print-out-paths "$FLAKE_REF" 2>/dev/null)
if [ -z "$opencode_store" ] || [ ! -d "$opencode_store/bin" ]; then
  echo "Error: Failed to build opencode from $FLAKE_REF" >&2
  exit 1
fi

exec "${opencode_store}/bin/opencode" "$@"
