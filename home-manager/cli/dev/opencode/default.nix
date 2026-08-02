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
  omoDir = "${config.home.homeDirectory}/.omo";

  # Base omo ("[opencode]" harness section) + per-host overrides.
  # See module/opencode for the option definition.
  omoBase = import ./omo-base.nix;

  # Extra skill sources, equivalent to the old @OPENCODE_CONFIG_DIR@ paths.
  # git-commit is deployed here by agent-skills (dotagents); final-review is
  # expected at the same location.
  omoSkills = {
    skills.sources = [
      "${configDir}/skill/final-review"
      "${configDir}/skill/git-commit"
    ];
  };

  omoHarness = lib.recursiveUpdate (lib.recursiveUpdate omoBase omoSkills) config.packs.opencode.omoOverrides;

  omoConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/omo.schema.json";
    "[opencode]" = omoHarness;
    # Keep the unification migration marker/history so the plugin never
    # re-runs legacy oh-my-openagent.json migrations over this managed file.
    legacy_migrations = {
      "${config.xdg.configHome}/opencode-go/oh-my-openagent.json" = [
        "model-version:openai/gpt-5.3-codex->openai/gpt-5.4"
        "model-version:openai/gpt-5.4->openai/gpt-5.5"
      ];
    };
    _migrations = [ "2026-07-opencode-config-unification" ];
  };

  omoJsonc = pkgs.writeText "omo.jsonc" (builtins.toJSON omoConfig);
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

  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" "agent-skills" ] ''
    # ~/.config/opencode (single profile, based on the former oc-go settings)
    mkdir -p "${configDir}"
    for f in opencode.jsonc AGENTS.md; do
      [ -f "${configDir}/$f" ] && mv -f "${configDir}/$f" "${configDir}/$f.old"
    done
    cp -f ${./opencode.jsonc} "${configDir}/opencode.jsonc"
    cp -f ${./AGENTS.md} "${configDir}/AGENTS.md"
    chmod u+w "${configDir}/opencode.jsonc" "${configDir}/AGENTS.md"

    # ~/.omo/omo.jsonc (oh-my-openagent unified config)
    mkdir -p "${omoDir}"
    [ -f "${omoDir}/omo.jsonc" ] && mv -f "${omoDir}/omo.jsonc" "${omoDir}/omo.jsonc.old"
    cp -f ${omoJsonc} "${omoDir}/omo.jsonc"
    chmod u+w "${omoDir}/omo.jsonc"
  '';
}
