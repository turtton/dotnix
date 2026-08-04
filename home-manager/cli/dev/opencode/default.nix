{
  config,
  lib,
  pkgs,
  isWsl,
  ...
}:
let
  configDir = "${config.xdg.configHome}/opencode";
in
{
  # ~/.omo/omo.jsonc (both harness sections) is managed by ../omo.

  home.packages =
    with pkgs;
    [
      opencode-latest
    ]
    ++ pkgs.lib.optionals (!isWsl) [
      opencode
    ];

  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # ~/.config/opencode (single profile, based on the former oc-go settings)
    mkdir -p "${configDir}"
    for f in opencode.jsonc AGENTS.md; do
      [ -f "${configDir}/$f" ] && mv -f "${configDir}/$f" "${configDir}/$f.old"
    done
    cp -f ${./opencode.jsonc} "${configDir}/opencode.jsonc"
    cp -f ${./AGENTS.md} "${configDir}/AGENTS.md"
    chmod u+w "${configDir}/opencode.jsonc" "${configDir}/AGENTS.md"
  '';
}
