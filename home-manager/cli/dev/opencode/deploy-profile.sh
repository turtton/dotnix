#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Profile definitions ----
declare -A CONFIG_DIR_SUFFIX
CONFIG_DIR_SUFFIX[main]="opencode"
CONFIG_DIR_SUFFIX[go]="opencode-go"
CONFIG_DIR_SUFFIX[cg]="opencode-cg"

declare -A CONFIG_SOURCE
CONFIG_SOURCE[main]="opencode.jsonc"
CONFIG_SOURCE[go]="opencode-go.jsonc"
CONFIG_SOURCE[cg]="opencode-cg.jsonc"

declare -A OPENAGENT_SOURCE
OPENAGENT_SOURCE[main]="oh-my-openagent.json"
OPENAGENT_SOURCE[go]="oh-my-openagent-go.json"
OPENAGENT_SOURCE[cg]="oh-my-openagent-cg.json"

# ---- Required commands ----
for cmd in diff rsync sed; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: Required command '$cmd' not found in PATH." >&2
    exit 1
  fi
done

# ---- Helper: escape string for sed replacement (delimiter |) ----
escape_sed_repl() {
  printf '%s\n' "$1" | sed 's/[&\/\|]/\\&/g'
}

# ---- Functions ----

usage() {
  cat >&2 <<EOF
Usage: $0 [-n|--dry-run] {main|go|cg}

  -n, --dry-run   Show diff of what would change without modifying anything.

Deploy opencode profile configuration files directly, bypassing Nix.
Useful for testing configuration changes without rebuilding.

Profiles:
  main   -> \${XDG_CONFIG_HOME:-\$HOME/.config}/opencode
  go     -> \${XDG_CONFIG_HOME:-\$HOME/.config}/opencode-go
  cg     -> \${XDG_CONFIG_HOME:-\$HOME/.config}/opencode-cg

Prerequisites:
  - Run this script with bash from home-manager/cli/dev/opencode/.
  - Requires: diff, rsync, sed (validated at startup).
  - For non-main profiles, main profile should have been deployed at least once
    (opencode.json and skills are mirrored from main).
EOF
}

# Print diff between a source file (after optional sed expression) and target file.
# Returns 0 (identical), 1 (different), 2 (target missing).
diff_with_target() {
  local label="$1"
  local src_file="$2"
  local tgt_file="$3"
  local sed_expr="${4:-}"

  local src_content
  if [[ -n $sed_expr ]]; then
    src_content=$(sed "$sed_expr" "$src_file")
  else
    src_content=$(cat "$src_file")
  fi

  if [[ ! -f $tgt_file ]]; then
    echo "  [$label] NEW FILE:"
    echo "$src_content" | sed 's/^/    + /'
    return 2
  fi

  local diff_out
  diff_out=$(diff -u "$tgt_file" <(echo "$src_content") 2>/dev/null || true)
  if [[ -z $diff_out ]]; then
    echo "  [$label] (identical)"
    return 0
  else
    echo "  [$label]"
    echo "$diff_out" | sed 's/^/    /'
    return 1
  fi
}

# Check whether opencode.json in non-main profile would change.
# Returns 0 (no change), 1 (would change).
opencode_json_status() {
  local pd="$1" md="$2" pn="$3"

  if [[ $pn == "cg" ]]; then
    if [[ -f $pd/opencode.json ]]; then
      echo "  [opencode.json] WILL BE REMOVED (cg profile)"
      return 1
    else
      echo "  [opencode.json] (already absent — no change)"
      return 0
    fi
  fi

  if [[ -f $md/opencode.json ]]; then
    if [[ -f $pd/opencode.json ]]; then
      if diff -q "$md/opencode.json" "$pd/opencode.json" &>/dev/null; then
        echo "  [opencode.json] (identical to main — no change)"
        return 0
      else
        echo "  [opencode.json] WILL BE UPDATED from main profile:"
        diff -u "$pd/opencode.json" "$md/opencode.json" 2>/dev/null | sed 's/^/    /' || true
        return 1
      fi
    else
      echo "  [opencode.json] WILL BE COPIED from main profile (new file)"
      return 1
    fi
  else
    echo "  [opencode.json] WARNING: main profile has no opencode.json — will be skipped"
    return 0
  fi
}

# Check whether skill directory in non-main profile would change.
# Returns 0 (no change), 1 (would change).
skills_status() {
  local pd="$1" md="$2"

  if [[ -d $md/skill ]]; then
    if [[ ! -d $pd/skill ]]; then
      echo "  [skills] WILL BE SYNCED from main profile (new)"
      return 1
    fi
    local dry_run
    dry_run=$(rsync -aLni --delete "$md/skill/" "$pd/skill/" 2>&1 || true)
    if [[ -z $dry_run ]]; then
      echo "  [skills] (already in sync — no change)"
      return 0
    else
      echo "  [skills] WILL BE SYNCED from main profile:"
      echo "$dry_run" | head -20 | sed 's/^/    /'
      local count
      count=$(echo "$dry_run" | wc -l)
      if ((count > 20)); then
        echo "    ... and $((count - 20)) more"
      fi
      return 1
    fi
  elif [[ -d $pd/skill ]]; then
    echo "  [skills] WILL BE REMOVED (no skills in main profile)"
    return 1
  else
    echo "  [skills] (no skills in either profile — no change)"
    return 0
  fi
}

# ---- Argument parsing ----
dry_run=false
while [[ $# -gt 0 ]]; do
  case "$1" in
  -n | --dry-run)
    dry_run=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  -*)
    echo "ERROR: Unknown option: $1" >&2
    usage
    exit 1
    ;;
  *)
    break
    ;;
  esac
done

profile="${1:-}"
if [[ -z $profile ]]; then
  usage
  exit 1
fi

if [[ -z ${CONFIG_DIR_SUFFIX[$profile]:-} ]]; then
  echo "ERROR: Unknown profile: $profile (valid: main, go, cg)" >&2
  exit 1
fi

profile_dir="${XDG_CONFIG_HOME:-$HOME/.config}/${CONFIG_DIR_SUFFIX[$profile]}"
main_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
config_source="${SCRIPT_DIR}/${CONFIG_SOURCE[$profile]}"
openagent_source="${SCRIPT_DIR}/${OPENAGENT_SOURCE[$profile]}"
agents_md="${SCRIPT_DIR}/AGENTS.md"

# ---- Source file validation ----
missing=false
for f in "$config_source" "$openagent_source" "$agents_md"; do
  if [[ ! -f $f ]]; then
    echo "ERROR: Source file not found: $f" >&2
    missing=true
  fi
done
if [[ $missing == true ]]; then
  exit 1
fi

# ---- Prerequisite check for non-main profiles ----
main_missing=false
if [[ $profile != "main" && ! -d $main_dir ]]; then
  main_missing=true
  echo "WARNING: Main profile directory ($main_dir) does not exist." >&2
  echo "  Non-main profiles mirror opencode.json and skills from the main profile." >&2
  echo "  Without it, extras will be skipped (existing files will NOT be deleted)." >&2
fi

# ---- Build sed expression for @OPENCODE_CONFIG_DIR@ ----
repl_escaped=$(escape_sed_repl "$profile_dir")
sed_expr="s|@OPENCODE_CONFIG_DIR@|${repl_escaped}|g"

# ---- Dry-run: show diff summary ----
if "$dry_run"; then
  echo "=== Dry run for profile '$profile' → $profile_dir ==="
  echo ""

  has_changes=false

  diff_with_target "opencode.jsonc" "$config_source" "$profile_dir/opencode.jsonc" && rc=$? || rc=$?
  if [[ $rc -gt 2 ]]; then exit 1; fi
  case $rc in 1 | 2) has_changes=true ;; esac

  diff_with_target "oh-my-openagent.json" "$openagent_source" "$profile_dir/oh-my-openagent.json" "$sed_expr" && rc=$? || rc=$?
  if [[ $rc -gt 2 ]]; then exit 1; fi
  case $rc in 1 | 2) has_changes=true ;; esac

  diff_with_target "AGENTS.md" "$agents_md" "$profile_dir/AGENTS.md" && rc=$? || rc=$?
  if [[ $rc -gt 2 ]]; then exit 1; fi
  case $rc in 1 | 2) has_changes=true ;; esac

  if [[ $profile != "main" && ! $main_missing ]]; then
    echo ""
    echo "--- Non-main profile extras ---"
    opencode_json_status "$profile_dir" "$main_dir" "$profile" && rc=$? || rc=$?
    if [[ $rc -gt 1 ]]; then exit 1; fi
    case $rc in 1) has_changes=true ;; esac

    skills_status "$profile_dir" "$main_dir" && rc=$? || rc=$?
    if [[ $rc -gt 1 ]]; then exit 1; fi
    case $rc in 1) has_changes=true ;; esac
  elif [[ $profile != "main" && $main_missing ]]; then
    echo ""
    echo "--- Non-main profile extras (SKIPPED — main profile missing) ---"
    echo "  [opencode.json] (skipped)"
    echo "  [skills] (skipped)"
  fi

  echo ""
  if "$has_changes"; then
    echo "Changes detected. Run without --dry-run to apply."
  else
    echo "All files are up to date — no changes needed."
  fi
  exit 0
fi

# ---- Normal mode: show diff and confirm ----
echo "=== Plan: deploy profile '$profile' → $profile_dir ==="
echo ""

diff_with_target "opencode.jsonc" "$config_source" "$profile_dir/opencode.jsonc" || true
diff_with_target "oh-my-openagent.json" "$openagent_source" "$profile_dir/oh-my-openagent.json" "$sed_expr" || true
diff_with_target "AGENTS.md" "$agents_md" "$profile_dir/AGENTS.md" || true

if [[ $profile != "main" && ! $main_missing ]]; then
  echo ""
  echo "--- Non-main profile extras ---"
  opencode_json_status "$profile_dir" "$main_dir" "$profile" || true
  skills_status "$profile_dir" "$main_dir" || true
elif [[ $profile != "main" && $main_missing ]]; then
  echo ""
  echo "--- Non-main profile extras (SKIPPED — main profile missing) ---"
fi

echo ""
if ! read -r -p "Apply these changes? [y/N] " reply; then
  echo "Cancelled."
  exit 1
fi
case "$reply" in
[yY] | [yY][eE][sS]) ;;
*)
  echo "Cancelled."
  exit 1
  ;;
esac

# ---- Apply ----

mkdir -p "$profile_dir"

# Backup existing files with nanosecond-granularity timestamp
backup_ts=$(date +%Y%m%d-%H%M%S)-$$
for f in opencode.jsonc oh-my-openagent.json AGENTS.md; do
  if [[ -f $profile_dir/$f ]]; then
    cp -f "$profile_dir/$f" "$profile_dir/$f.${backup_ts}.bak"
    echo "  Backed up: $f → $f.${backup_ts}.bak"
  fi
done

# Deploy opencode.jsonc
cp -f "$config_source" "$profile_dir/opencode.jsonc"
chmod u+w "$profile_dir/opencode.jsonc"
echo "  Deployed: opencode.jsonc"

# Deploy oh-my-openagent.json with @OPENCODE_CONFIG_DIR@ substitution
sed "$sed_expr" "$openagent_source" >"$profile_dir/oh-my-openagent.json"
chmod u+w "$profile_dir/oh-my-openagent.json"
echo "  Deployed: oh-my-openagent.json"

# Deploy AGENTS.md
cp -f "$agents_md" "$profile_dir/AGENTS.md"
chmod u+w "$profile_dir/AGENTS.md"
echo "  Deployed: AGENTS.md"

# Handle extras for non-main profiles
if [[ $profile != "main" ]]; then
  if "$main_missing"; then
    echo "  (Skipped opencode.json and skills — main profile missing)"
  else
    # Guard: profile_dir is never empty or root
    if [[ -z $profile_dir || $profile_dir == "/" ]]; then
      echo "FATAL: profile_dir resolved to '$profile_dir' — refusing to operate." >&2
      exit 1
    fi

    # Back up opencode.json before modifying
    if [[ -f $profile_dir/opencode.json ]]; then
      cp -f "$profile_dir/opencode.json" "$profile_dir/opencode.json.${backup_ts}.bak"
      echo "  Backed up: opencode.json → opencode.json.${backup_ts}.bak"
    fi

    if [[ $profile == "cg" ]]; then
      rm -f "$profile_dir/opencode.json"
      echo "  Removed: opencode.json (cg profile)"
    elif [[ -f $main_dir/opencode.json ]]; then
      cp -f "$main_dir/opencode.json" "$profile_dir/opencode.json"
      chmod u+w "$profile_dir/opencode.json"
      echo "  Copied: opencode.json from main profile"
    else
      echo "  Skipped: opencode.json (not found in main profile)" >&2
    fi

    # Back up skill directory before modifying
    if [[ -d $profile_dir/skill ]]; then
      cp -r "$profile_dir/skill" "$profile_dir/skill.${backup_ts}.bak"
      echo "  Backed up: skill → skill.${backup_ts}.bak"
    fi

    if [[ -d $main_dir/skill ]]; then
      mkdir -p "$profile_dir/skill"
      rsync -aL --delete "$main_dir/skill/" "$profile_dir/skill/"
      chmod -R u+w "$profile_dir/skill"
      echo "  Synced: skills from main profile"
    elif [[ -d $profile_dir/skill ]]; then
      rm -rf "$profile_dir/skill"
      echo "  Removed: skill directory (no skills in main profile)"
    fi
  fi
fi

echo ""
echo "Profile '$profile' deployed to $profile_dir."
echo "Run with: OPENCODE_CONFIG_DIR=${profile_dir} opencode"
