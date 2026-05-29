{ config, lib, ... }:
let
  configDir = "${config.xdg.configHome}/opencode";
  altConfigDir = "${config.xdg.configHome}/opencode-alt";
  skillSrc = ../../../../.agents/skills;
in
{
  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Rotate previous configs to -old (keep one generation)
    for f in opencode.jsonc oh-my-openagent.json dcp.jsonc AGENTS.md; do
      [ -f "${configDir}/$f" ] && mv -f "${configDir}/$f" "${configDir}/$f.old"
    done
    rm -rf "${configDir}/skill-old"
    [ -d "${configDir}/skill" ] && mv "${configDir}/skill" "${configDir}/skill-old"

    mkdir -p "${configDir}/skill/git-commit"
    mkdir -p "${configDir}/skill/final-review"

    cp -f "${./opencode.jsonc}" "${configDir}/opencode.jsonc"
    cp -f "${./oh-my-openagent.json}" "${configDir}/oh-my-openagent.json"
    sed -i 's|@OPENCODE_CONFIG_DIR@|${configDir}|g' "${configDir}/oh-my-openagent.json"
    cp -f "${./dcp.jsonc}" "${configDir}/dcp.jsonc"
    cp -f "${./AGENTS.md}" "${configDir}/AGENTS.md"

    cp -f "${skillSrc}/git-commit/SKILL.md" "${configDir}/skill/git-commit/SKILL.md"
    cp -f "${skillSrc}/git-commit/GUIDE.md" "${configDir}/skill/git-commit/GUIDE.md"
    cp -f "${skillSrc}/final-review/SKILL.md" "${configDir}/skill/final-review/SKILL.md"
    cp -f "${skillSrc}/final-review/GUIDE.md" "${configDir}/skill/final-review/GUIDE.md"

    chmod u+w "${configDir}/opencode.jsonc" "${configDir}/oh-my-openagent.json" "${configDir}/dcp.jsonc" "${configDir}/AGENTS.md"
    chmod -R u+w "${configDir}/skill"

    # Alt profile (ChatGPT Team + Cursor + OpenCode Go)
    for f in opencode.jsonc oh-my-openagent.json dcp.jsonc AGENTS.md; do
      [ -f "${altConfigDir}/$f" ] && mv -f "${altConfigDir}/$f" "${altConfigDir}/$f.old"
    done
    rm -rf "${altConfigDir}/skill-old"
    [ -d "${altConfigDir}/skill" ] && mv "${altConfigDir}/skill" "${altConfigDir}/skill-old"

    mkdir -p "${altConfigDir}/skill/git-commit"
    mkdir -p "${altConfigDir}/skill/final-review"

    cp -f "${./opencode-alt.jsonc}" "${altConfigDir}/opencode.jsonc"
    cp -f "${./oh-my-openagent-alt.json}" "${altConfigDir}/oh-my-openagent.json"
    sed -i 's|@OPENCODE_CONFIG_DIR@|${altConfigDir}|g' "${altConfigDir}/oh-my-openagent.json"
    cp -f "${./dcp.jsonc}" "${altConfigDir}/dcp.jsonc"
    cp -f "${./AGENTS.md}" "${altConfigDir}/AGENTS.md"

    # Copy cursor-acp provider definition (opencode.json) from main profile
    if [ -f "${configDir}/opencode.json" ]; then
      cp -f "${configDir}/opencode.json" "${altConfigDir}/opencode.json"
      chmod u+w "${altConfigDir}/opencode.json"
    else
      # Remove stale provider config and warn
      rm -f "${altConfigDir}/opencode.json"
      echo "WARNING: ${configDir}/opencode.json not found. cursor-acp provider unavailable in alt profile." >&2
      echo "Run 'opencode' (main profile) first to generate it via the cursor-acp plugin." >&2
    fi

    cp -f "${skillSrc}/git-commit/SKILL.md" "${altConfigDir}/skill/git-commit/SKILL.md"
    cp -f "${skillSrc}/git-commit/GUIDE.md" "${altConfigDir}/skill/git-commit/GUIDE.md"
    cp -f "${skillSrc}/final-review/SKILL.md" "${altConfigDir}/skill/final-review/SKILL.md"
    cp -f "${skillSrc}/final-review/GUIDE.md" "${altConfigDir}/skill/final-review/GUIDE.md"

    chmod u+w "${altConfigDir}/opencode.jsonc" "${altConfigDir}/oh-my-openagent.json" "${altConfigDir}/dcp.jsonc" "${altConfigDir}/AGENTS.md"
    chmod -R u+w "${altConfigDir}/skill"
  '';

  home.shellAliases.oc-alt = "OPENCODE_CONFIG_DIR=${altConfigDir} CURSOR_API_KEY=\${$(rbw get cursor-api):-$CURSOR_API_KEY} opencode";
}
