{
  config,
  lib,
  pkgs,
  inputs,
  isWsl,
  ...
}:
let
  configDir = "${config.xdg.configHome}/opencode";
  goConfigDir = "${config.xdg.configHome}/opencode-go";

  replaceConfigDir =
    dir: content: builtins.replaceStrings [ "@OPENCODE_CONFIG_DIR@" ] [ dir ] content;

  ohMyOpenagentMain = pkgs.writeText "oh-my-openagent.json" (
    replaceConfigDir configDir (builtins.readFile ./oh-my-openagent.json)
  );

  ohMyOpenagentGo = pkgs.writeText "oh-my-openagent-go.json" (
    replaceConfigDir goConfigDir (builtins.readFile ./oh-my-openagent-go.json)
  );
in
{
  imports = [
    inputs.skills-catalog.homeManagerModules.default
  ];

  home.packages =
    with pkgs;
    [
      opencode-latest
    ]
    ++ pkgs.lib.optionals (!isWsl) [
      opencode
    ];

  home.shellAliases.oc-go = "OPENCODE_CONFIG_DIR=${goConfigDir} opencode";

  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" "agent-skills" ] ''
    # Rotate previous configs to -old (keep one generation)
    for f in opencode.jsonc oh-my-openagent.json dcp.jsonc AGENTS.md; do
      [ -f "${configDir}/$f" ] && mv -f "${configDir}/$f" "${configDir}/$f.old"
    done

    mkdir -p "${configDir}"

    cp -f "${./opencode.jsonc}" "${configDir}/opencode.jsonc"
    cp -f ${ohMyOpenagentMain} "${configDir}/oh-my-openagent.json"
    cp -f "${./dcp.jsonc}" "${configDir}/dcp.jsonc"
    cp -f "${./AGENTS.md}" "${configDir}/AGENTS.md"

    chmod u+w "${configDir}/opencode.jsonc" "${configDir}/oh-my-openagent.json" "${configDir}/dcp.jsonc" "${configDir}/AGENTS.md"

    # Go profile (ChatGPT Team + Cursor + OpenCode Go)
    for f in opencode.jsonc oh-my-openagent.json dcp.jsonc AGENTS.md; do
      [ -f "${goConfigDir}/$f" ] && mv -f "${goConfigDir}/$f" "${goConfigDir}/$f.old"
    done

    mkdir -p "${goConfigDir}"

    cp -f "${./opencode-go.jsonc}" "${goConfigDir}/opencode.jsonc"
    cp -f ${ohMyOpenagentGo} "${goConfigDir}/oh-my-openagent.json"
    cp -f "${./dcp.jsonc}" "${goConfigDir}/dcp.jsonc"
    cp -f "${./AGENTS.md}" "${goConfigDir}/AGENTS.md"

    # Copy cursor-acp provider definition (opencode.json) from main profile
    if [ -f "${configDir}/opencode.json" ]; then
      cp -f "${configDir}/opencode.json" "${goConfigDir}/opencode.json"
      chmod u+w "${goConfigDir}/opencode.json"
    else
      # Remove stale provider config and warn
      rm -f "${goConfigDir}/opencode.json"
      echo "WARNING: ${configDir}/opencode.json not found. cursor-acp provider unavailable in go profile." >&2
      echo "Run 'opencode' (main profile) first to generate it via the cursor-acp plugin." >&2
    fi

    # Mirror skills from main profile (deployed by agent-skills) to go profile
    if [ -d "${configDir}/skill" ]; then
      mkdir -p "${goConfigDir}/skill"
      ${pkgs.rsync}/bin/rsync -aL --delete "${configDir}/skill/" "${goConfigDir}/skill/"
    else
      rm -rf "${goConfigDir}/skill"
    fi

    chmod u+w "${goConfigDir}/opencode.jsonc" "${goConfigDir}/oh-my-openagent.json" "${goConfigDir}/dcp.jsonc" "${goConfigDir}/AGENTS.md"
    [ -d "${goConfigDir}/skill" ] && chmod -R u+w "${goConfigDir}/skill"
  '';
}
