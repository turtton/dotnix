{ config, lib, ... }:
let
  configDir = "${config.xdg.configHome}/opencode";
in
{
  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${configDir}/skill/git-commit"
    mkdir -p "${configDir}/skill/final-review"

    cp -f "${./opencode.jsonc}" "${configDir}/opencode.jsonc"
    cp -f "${./oh-my-openagent.json}" "${configDir}/oh-my-openagent.json"
    sed -i 's|@OPENCODE_CONFIG_DIR@|${configDir}|g' "${configDir}/oh-my-openagent.json"
    cp -f "${./dcp.jsonc}" "${configDir}/dcp.jsonc"
    cp -f "${./AGENTS.md}" "${configDir}/AGENTS.md"

    cp -f "${./skill/git-commit/SKILL.md}" "${configDir}/skill/git-commit/SKILL.md"
    cp -f "${./skill/git-commit/GUIDE.md}" "${configDir}/skill/git-commit/GUIDE.md"
    cp -f "${./skill/final-review/SKILL.md}" "${configDir}/skill/final-review/SKILL.md"
    cp -f "${./skill/final-review/GUIDE.md}" "${configDir}/skill/final-review/GUIDE.md"

    chmod u+w "${configDir}/opencode.jsonc" "${configDir}/oh-my-openagent.json" "${configDir}/dcp.jsonc" "${configDir}/AGENTS.md"
    chmod -R u+w "${configDir}/skill"
  '';
}
