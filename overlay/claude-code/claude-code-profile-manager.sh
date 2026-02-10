#!/usr/bin/env bash

# claude-profile: Subcommand-based CLI for managing Claude Code profiles

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PROFILE_DIR="$CONFIG_DIR/profile-claude-code"
PROFILES_FILE="$PROFILE_DIR/profiles.conf"
CURRENT_FILE="$PROFILE_DIR/current"

# Ensure profile directory and config exist
mkdir -p "$PROFILE_DIR"
[ -f "$PROFILES_FILE" ] || touch "$PROFILES_FILE"

# Validate profile name: only alphanumeric, underscore, hyphen
validate_name() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "Error: Profile name cannot be empty" >&2
    return 1
  fi
  if ! [[ $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Profile name must match [a-zA-Z0-9_-]+" >&2
    return 1
  fi
  if [ "$name" = "default" ]; then
    echo "Error: 'default' is a reserved name" >&2
    return 1
  fi
  return 0
}

# Get current active profile name (empty string means default)
get_current() {
  if [ -f "$CURRENT_FILE" ]; then
    cat "$CURRENT_FILE"
  fi
}

cmd_list() {
  local current
  current=$(get_current)

  echo "Profiles:"
  if [ -z "$current" ]; then
    echo "  * default"
  else
    echo "    default"
  fi

  if [ -s "$PROFILES_FILE" ]; then
    while IFS='|' read -r name path; do
      if [ "$name" = "$current" ]; then
        echo "  * $name ($path)"
      else
        echo "    $name ($path)"
      fi
    done <"$PROFILES_FILE"
  fi
}

cmd_show() {
  local current
  current=$(get_current)
  if [ -z "$current" ]; then
    echo "default"
  else
    echo "$current"
  fi
}

cmd_create() {
  local name="$1"
  validate_name "$name" || return 1

  # Check if profile already exists
  if grep -q "^${name}|" "$PROFILES_FILE" 2>/dev/null; then
    echo "Error: Profile '$name' already exists" >&2
    return 1
  fi

  local profile_path="$CONFIG_DIR/claude-code-$name"
  mkdir -p "$profile_path"

  echo "$name|$profile_path" >>"$PROFILES_FILE"
  echo "Created profile '$name' at $profile_path"
}

cmd_delete() {
  local name="$1"
  validate_name "$name" || return 1

  # Check if profile exists
  if ! grep -q "^${name}|" "$PROFILES_FILE" 2>/dev/null; then
    echo "Error: Profile '$name' not found" >&2
    return 1
  fi

  local profile_path
  profile_path=$(grep "^${name}|" "$PROFILES_FILE" | head -n1 | cut -d'|' -f2)

  # Confirm deletion
  echo -n "Delete profile '$name' and its data at $profile_path? [y/N]: "
  read -r confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Deletion cancelled"
    return 0
  fi

  # Delete profile directory
  if [ -d "$profile_path" ]; then
    rm -rf "$profile_path"
  fi

  # Remove from profiles.conf using pattern match
  if [[ $OSTYPE == "darwin"* ]]; then
    sed -i '' "/^${name}|/d" "$PROFILES_FILE"
  else
    sed -i "/^${name}|/d" "$PROFILES_FILE"
  fi

  # If this was the active profile, reset to default
  local current
  current=$(get_current)
  if [ "$current" = "$name" ]; then
    rm -f "$CURRENT_FILE"
    echo "Active profile reset to default"
  fi

  echo "Deleted profile '$name'"
}

cmd_switch() {
  local name="$1"

  # "default" resets to default profile
  if [ "$name" = "default" ]; then
    rm -f "$CURRENT_FILE"
    echo "Switched to default profile"
    return 0
  fi

  validate_name "$name" || return 1

  # Check if profile exists
  if ! grep -q "^${name}|" "$PROFILES_FILE" 2>/dev/null; then
    echo "Error: Profile '$name' not found" >&2
    return 1
  fi

  echo "$name" >"$CURRENT_FILE"
  echo "Switched to profile '$name'"
}

cmd_help() {
  echo "Usage: claude-profile <command> [args]"
  echo ""
  echo "Commands:"
  echo "  list              List all profiles (* = active)"
  echo "  show              Print the active profile name"
  echo "  create <name>     Create a new profile"
  echo "  delete <name>     Delete a profile (with confirmation)"
  echo "  switch <name>     Switch the active profile (use 'default' to reset)"
  echo "  help              Show this help message"
}

# Main dispatch
case "${1:-}" in
list)
  cmd_list
  ;;
show)
  cmd_show
  ;;
create)
  if [ -z "${2:-}" ]; then
    echo "Usage: claude-profile create <name>" >&2
    exit 1
  fi
  cmd_create "$2"
  ;;
delete)
  if [ -z "${2:-}" ]; then
    echo "Usage: claude-profile delete <name>" >&2
    exit 1
  fi
  cmd_delete "$2"
  ;;
switch)
  if [ -z "${2:-}" ]; then
    echo "Usage: claude-profile switch <name>" >&2
    exit 1
  fi
  cmd_switch "$2"
  ;;
help | --help | -h)
  cmd_help
  ;;
"")
  cmd_help
  exit 1
  ;;
*)
  echo "Unknown command: $1" >&2
  echo "Run 'claude-profile help' for usage" >&2
  exit 1
  ;;
esac
