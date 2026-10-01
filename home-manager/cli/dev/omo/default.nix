{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  configDir = "${config.xdg.configHome}/opencode";
  omoDir = "${config.home.homeDirectory}/.omo";

  opencodeBase = import ./opencode-base.nix;

  senpiBase = import ./senpi-base.nix;

  omoSkills = {
    skills.sources = [
      "${configDir}/skill/git-commit"
    ];
  };

  opencodeHarness = lib.recursiveUpdate (lib.recursiveUpdate opencodeBase omoSkills) config.packs.opencode.omoOverrides;

  omoConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/omo.schema.json";
    "[opencode]" = opencodeHarness;
    "[native]" = senpiBase;
    # Keep the unification migration marker/history so the plugin never
    # re-runs legacy oh-my-openagent.json migrations over this managed file.
    legacy_migrations = {
      "${config.xdg.configHome}/opencode-go/oh-my-openagent.json" = [
        "model-version:openai/gpt-5.3-codex->openai/gpt-5.4"
        "model-version:openai/gpt-5.4->openai/gpt-5.5"
      ];
    };
    _migrations = [
      "2026-07-opencode-config-unification"
      "2026-08-reasoning-unification"
    ];
  };

  omoJsonc = pkgs.writeText "omo.jsonc" (builtins.toJSON omoConfig);
in
{
  imports = [
    inputs.skills-catalog.homeManagerModules.default
  ];

  home.activation.omo = lib.hm.dag.entryAfter [ "writeBoundary" "agent-skills" ] ''
    # ~/.omo/omo.jsonc (oh-my-openagent unified config)
    mkdir -p "${omoDir}"
    [ -f "${omoDir}/omo.jsonc" ] && mv -f "${omoDir}/omo.jsonc" "${omoDir}/omo.jsonc.old"
    cp -f ${omoJsonc} "${omoDir}/omo.jsonc"
    chmod u+w "${omoDir}/omo.jsonc"
  '';
}
