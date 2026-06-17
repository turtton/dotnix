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
  - Run from home-manager/cli/dev/opencode/ in the dotnix repo.
  - For non-main profiles, main profile must have been deployed at least once
    (opencode.json and skills are mirrored from main).
EOF
}

# Show diff between a source file (after optional sed substitution) and target file.
# Returns 0 if files are identical, 1 if different, 2 if target doesn't exist.
diff_with_target() {
  local label="$1" # display label
  local src_file="$2"
  local tgt_file="$3"
  local sed_expr="${4:-}" # optional sed expression (e.g. "s|@X@|Y|g")

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

# Summarize opencode.json status for non-main profiles (dry-run).
show_opencode_json_status() {
  local pd="$1" md="$2" pn="$3"

  if [[ $pn == "cg" ]]; then
    if [[ -f $pd/opencode.json ]]; then
      echo "  [opencode.json] WILL BE REMOVED (cg profile does not need external providers)"
    else
      echo "  [opencode.json] (already absent — no change)"
    fi
  elif [[ -f $md/opencode.json ]]; then
    if diff -q "$md/opencode.json" "$pd/opencode.json" &>/dev/null 2>/dev/null; then
      echo "  [opencode.json] (identical to main — no change)"
    elif [[ -f $pd/opencode.json ]]; then
      echo "  [opencode.json] WILL BE UPDATED from main profile:"
      diff -u "$pd/opencode.json" "$md/opencode.json" 2>/dev/null | sed 's/^/    /' || true
    else
      echo "  [opencode.json] WILL BE COPIED from main profile (new file)"
    fi
  else
    echo "  [opencode.json] WARNING: main profile has no opencode.json — provider unavailable"
  fi
}

# Summarize skill directory changes (dry-run).
show_skills_status() {
  local pd="$1" md="$2"

  if [[ -d $md/skill ]]; then
    local dry_run
    dry_run=$(rsync -aLn --delete "$md/skill/" "$pd/skill/" 2>&1 || true)
    if [[ -z $dry_run ]]; then
      echo "  [skills] (already in sync — no change)"
    else
      echo "  [skills] changes from main:"
      echo "$dry_run" | head -20 | sed 's/^/    /'
      local count
      count=$(echo "$dry_run" | wc -l)
      if ((count > 20)); then
        echo "    ... and $((count - 20)) more"
      fi
    fi
  elif [[ -d $pd/skill ]]; then
    echo "  [skills] WILL BE REMOVED (no skills in main profile)"
  else
    echo "  [skills] (no skills in either profile — no change)"
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
"$missing" && exit 1

if [[ $profile != "main" && ! -d $main_dir ]]; then
  echo "WARNING: Main profile directory ($main_dir) does not exist." >&2
  echo "Non-main profiles mirror opencode.json and skills from the main profile." >&2
  echo "Run 'deploy-profile.sh main' or the Nix activation script first." >&2
  echo "Continuing anyway (opencode.json and skills will be skipped)." >&2
fi

# ---- Dry-run: show diff summary ----
if "$dry_run"; then
  echo "=== Dry run for profile '$profile' → $profile_dir ==="
  echo ""

  mkdir -p "$profile_dir"

  has_changes=false

  diff_with_target "opencode.jsonc" "$config_source" "$profile_dir/opencode.jsonc" && rc=$? || rc=$?
  case $rc in
  1) has_changes=true ;;
  2) has_changes=true ;;
  esac

  diff_with_target "oh-my-openagent.json" "$openagent_source" "$profile_dir/oh-my-openagent.json" "s|@OPENCODE_CONFIG_DIR@|${profile_dir}|g" && rc=$? || rc=$?
  case $rc in
  1) has_changes=true ;;
  2) has_changes=true ;;
  esac

  diff_with_target "AGENTS.md" "$agents_md" "$profile_dir/AGENTS.md" && rc=$? || rc=$?
  case $rc in
  1) has_changes=true ;;
  2) has_changes=true ;;
  esac

  if [[ $profile != "main" ]]; then
    echo ""
    echo "--- Non-main profile extras ---"
    show_opencode_json_status "$profile_dir" "$main_dir" "$profile"
    show_skills_status "$profile_dir" "$main_dir"
  fi

  echo ""
  if "$has_changes"; then
    echo "Changes detected. Run without --dry-run to apply."
  else
    echo "All files are up to date — no changes needed."
  fi
  exit 0
fi

# ---- Confirmation with diff preview ----
echo "=== Plan: deploy profile '$profile' → $profile_dir ==="
echo ""

mkdir -p "$profile_dir"

diff_with_target "opencode.jsonc" "$config_source" "$profile_dir/opencode.jsonc" || true
diff_with_target "oh-my-openagent.json" "$openagent_source" "$profile_dir/oh-my-openagent.json" "s|@OPENCODE_CONFIG_DIR@|${profile_dir}|g" || true
diff_with_target "AGENTS.md" "$agents_md" "$profile_dir/AGENTS.md" || true

if [[ $profile != "main" ]]; then
  echo ""
  echo "--- Non-main profile extras ---"
  show_opencode_json_status "$profile_dir" "$main_dir" "$profile"
  show_skills_status "$profile_dir" "$main_dir"
fi

echo ""
read -r -p "Apply these changes? [y/N] " reply
case "$reply" in
[yY] | [yY][eE][sS]) ;;
*)
  echo "Cancelled."
  exit 1
  ;;
esac

# ---- Apply ----

# Backup existing files with timestamp
backup_ts=$(date +%Y%m%d-%H%M%S)
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
sed "s|@OPENCODE_CONFIG_DIR@|${profile_dir}|g" "$openagent_source" >"$profile_dir/oh-my-openagent.json"
chmod u+w "$profile_dir/oh-my-openagent.json"
echo "  Deployed: oh-my-openagent.json"

# Deploy AGENTS.md
cp -f "$agents_md" "$profile_dir/AGENTS.md"
chmod u+w "$profile_dir/AGENTS.md"
echo "  Deployed: AGENTS.md"

# Handle opencode.json for non-main profiles
if [[ $profile_dir != "$main_dir" ]]; then
  if [[ $profile == "cg" ]]; then
    rm -f "$profile_dir/opencode.json"
    echo "  Removed: opencode.json (cg profile)"
  elif [[ -f $main_dir/opencode.json ]]; then
    cp -f "$main_dir/opencode.json" "$profile_dir/opencode.json"
    chmod u+w "$profile_dir/opencode.json"
    echo "  Copied: opencode.json from main profile"
  else
    rm -f "$profile_dir/opencode.json"
    echo "  WARNING: ${main_dir}/opencode.json not found." >&2
    echo "  cursor-acp provider unavailable in '$profile' profile." >&2
  fi

  # Mirror skills from main profile (guard: profile_dir is never empty or root)
  if [[ -z $profile_dir || $profile_dir == "/" ]]; then
    echo "FATAL: profile_dir resolved to '$profile_dir' — refusing to operate." >&2
    exit 1
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

echo ""
echo "Profile '$profile' deployed to $profile_dir."
echo "Run with: OPENCODE_CONFIG_DIR=${profile_dir} opencode"
