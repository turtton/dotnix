{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  configDir = "${config.xdg.configHome}/opencode";
  altConfigDir = "${config.xdg.configHome}/opencode-alt";
in
{
  imports = [
    inputs.skills-catalog.homeManagerModules.default
  ];

  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" "agent-skills" ] ''
    # Rotate previous configs to -old (keep one generation)
    for f in opencode.jsonc oh-my-openagent.json dcp.jsonc AGENTS.md; do
      [ -f "${configDir}/$f" ] && mv -f "${configDir}/$f" "${configDir}/$f.old"
    done

    mkdir -p "${configDir}"

    cp -f "${./opencode.jsonc}" "${configDir}/opencode.jsonc"
    cp -f "${./oh-my-openagent.json}" "${configDir}/oh-my-openagent.json"
    sed -i 's|@OPENCODE_CONFIG_DIR@|${configDir}|g' "${configDir}/oh-my-openagent.json"
    cp -f "${./dcp.jsonc}" "${configDir}/dcp.jsonc"
    cp -f "${./AGENTS.md}" "${configDir}/AGENTS.md"

    chmod u+w "${configDir}/opencode.jsonc" "${configDir}/oh-my-openagent.json" "${configDir}/dcp.jsonc" "${configDir}/AGENTS.md"

    # Alt profile (ChatGPT Team + Cursor + OpenCode Go)
    for f in opencode.jsonc oh-my-openagent.json dcp.jsonc AGENTS.md; do
      [ -f "${altConfigDir}/$f" ] && mv -f "${altConfigDir}/$f" "${altConfigDir}/$f.old"
    done

    mkdir -p "${altConfigDir}"

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

    # Mirror skills from main profile (deployed by agent-skills) to alt profile
    if [ -d "${configDir}/skill" ]; then
      mkdir -p "${altConfigDir}/skill"
      ${pkgs.rsync}/bin/rsync -aL --delete "${configDir}/skill/" "${altConfigDir}/skill/"
    else
      rm -rf "${altConfigDir}/skill"
    fi

    chmod u+w "${altConfigDir}/opencode.jsonc" "${altConfigDir}/oh-my-openagent.json" "${altConfigDir}/dcp.jsonc" "${altConfigDir}/AGENTS.md"
    [ -d "${altConfigDir}/skill" ] && chmod -R u+w "${altConfigDir}/skill"
  '';

  home.shellAliases.oc-alt = "OPENCODE_CONFIG_DIR=${altConfigDir} CURSOR_API_KEY=\${$(rbw get cursor-api):-$CURSOR_API_KEY} opencode";
}
