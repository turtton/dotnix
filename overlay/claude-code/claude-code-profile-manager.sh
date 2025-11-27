#!/usr/bin/env bash

# Get config directory
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PROFILE_DIR="$CONFIG_DIR/profile-claude-code"
PROFILES_FILE="$PROFILE_DIR/profiles.conf"

# Create profile directory if it doesn't exist
mkdir -p "$PROFILE_DIR"

# Initialize profiles file if it doesn't exist
if [ ! -f "$PROFILES_FILE" ]; then
  touch "$PROFILES_FILE"
fi

# Function to list all profiles
list_profiles() {
  echo "=== Claude Code Profiles ==="
  echo "0) Default (no CLAUDE_CONFIG_DIR)"
  if [ -s "$PROFILES_FILE" ]; then
    local i=1
    while IFS='|' read -r name path; do
      echo "$i) $name"
      ((i++))
    done <"$PROFILES_FILE"
  else
    echo "(No custom profiles found)"
  fi
  echo
}

# Function to create a new profile
create_profile() {
  echo -n "Enter profile name: "
  read -r profile_name

  # Validate profile name
  if [ -z "$profile_name" ]; then
    echo "Error: Profile name cannot be empty"
    return 1
  fi

  # Check if profile already exists
  if grep -q "^$profile_name|" "$PROFILES_FILE"; then
    echo "Error: Profile '$profile_name' already exists"
    return 1
  fi

  # Create profile directory
  profile_path="$CONFIG_DIR/claude-code-$profile_name"
  mkdir -p "$profile_path"

  # Save profile to config
  echo "$profile_name|$profile_path" >>"$PROFILES_FILE"

  echo "Profile '$profile_name' created successfully at $profile_path"
}

# Function to delete a profile
delete_profile() {
  if [ ! -s "$PROFILES_FILE" ]; then
    echo "No profiles to delete"
    return 1
  fi

  echo "Select profile to delete:"
  list_profiles
  echo -n "Enter profile number to delete: "
  read -r profile_num

  # Validate input
  if ! [[ $profile_num =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid selection"
    return 1
  fi

  # Check if trying to delete default profile
  if [ "$profile_num" = "0" ]; then
    echo "Error: Cannot delete default profile"
    return 1
  fi

  # Get profile info
  local profile_info=$(sed -n "${profile_num}p" "$PROFILES_FILE")
  if [ -z "$profile_info" ]; then
    echo "Error: Invalid profile number"
    return 1
  fi

  local profile_name=$(echo "$profile_info" | cut -d'|' -f1)
  local profile_path=$(echo "$profile_info" | cut -d'|' -f2)

  # Confirm deletion
  echo -n "Delete profile '$profile_name' and its data? [y/N]: "
  read -r confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Deletion cancelled"
    return 0
  fi

  # Delete profile directory
  if [ -d "$profile_path" ]; then
    rm -rf "$profile_path"
  fi

  # Remove from profiles file
  if [[ $OSTYPE == "darwin"* ]]; then
    sed -i '' "${profile_num}d" "$PROFILES_FILE"
  else
    sed -i "${profile_num}d" "$PROFILES_FILE"
  fi

  echo "Profile '$profile_name' deleted successfully"
}

# Function to select and launch profile
launch_profile() {
  echo "Select profile to launch:"
  list_profiles
  echo -n "Enter profile number: "
  read -r profile_num

  # Validate input
  if ! [[ $profile_num =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid selection"
    return 1
  fi

  # Handle default profile
  if [ "$profile_num" = "0" ]; then
    echo "Launching Claude Code with default profile..."
    @claude-code@
    return 0
  fi

  # Get profile info
  local profile_info=$(sed -n "${profile_num}p" "$PROFILES_FILE")
  if [ -z "$profile_info" ]; then
    echo "Error: Invalid profile number"
    return 1
  fi

  local profile_name=$(echo "$profile_info" | cut -d'|' -f1)
  local profile_path=$(echo "$profile_info" | cut -d'|' -f2)

  echo "Launching Claude Code with profile '$profile_name'..."

  # Launch Claude Code with the profile's config directory
  CLAUDE_CONFIG_DIR="$profile_path" @claude-code@
}

# Main menu
main() {
  while true; do
    list_profiles
    echo "Actions:"
    echo "  [number] - Select and launch profile"
    echo "  a - Create new profile"
    echo "  d - Delete profile"
    echo "  q - Quit"
    echo
    echo -n "Choose action: "
    read -r action

    case "$action" in
    a | A)
      create_profile
      ;;
    d | D)
      delete_profile
      ;;
    q | Q)
      echo "Goodbye!"
      exit 0
      ;;
    [0-9]*)
      # User entered a number, try to launch that profile
      if [ "$action" = "0" ]; then
        echo "Launching Claude Code with default profile..."
        @claude-code@
        exit 0
      else
        profile_info=$(sed -n "${action}p" "$PROFILES_FILE")
        if [ -n "$profile_info" ]; then
          profile_name=$(echo "$profile_info" | cut -d'|' -f1)
          profile_path=$(echo "$profile_info" | cut -d'|' -f2)
          echo "Launching Claude Code with profile '$profile_name'..."
          CLAUDE_CONFIG_DIR="$profile_path" @claude-code@
          exit 0
        else
          echo "Error: Invalid profile number"
        fi
      fi
      ;;
    *)
      echo "Invalid action"
      ;;
    esac

    echo
    echo "Press Enter to continue..."
    read -r
    clear
  done
}

# Check if profile number was provided as first argument
if [ -n "$1" ]; then
  if [[ $1 =~ ^[0-9]+$ ]]; then
    # Handle default profile
    if [ "$1" = "0" ]; then
      echo "Launching Claude Code with default profile..."
      @claude-code@
      exit 0
    fi

    # Get profile info
    profile_info=$(sed -n "${1}p" "$PROFILES_FILE")
    if [ -n "$profile_info" ]; then
      profile_name=$(echo "$profile_info" | cut -d'|' -f1)
      profile_path=$(echo "$profile_info" | cut -d'|' -f2)
      echo "Launching Claude Code with profile '$profile_name'..."
      CLAUDE_CONFIG_DIR="$profile_path" @claude-code@
      exit 0
    else
      echo "Error: Invalid profile number '$1'"
      echo "Available profiles:"
      list_profiles
      exit 1
    fi
  else
    echo "Error: Profile number must be a valid number"
    echo "Usage: $0 [profile_number]"
    exit 1
  fi
fi

# Run main function if no arguments provided
main
