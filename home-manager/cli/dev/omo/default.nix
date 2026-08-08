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

  # Base omo "[opencode]" harness section + per-host overrides.
  # See module/opencode for the option definition.
  opencodeBase = import ./opencode-base.nix;

  # Base omo "[senpi]" harness section. senpi resolves only its own section
  # (no fallback to "[opencode]"), so it must be managed here explicitly or
  # every switch drops it. See ./senpi-base.nix header for provenance.
  senpiBase = import ./senpi-base.nix;

  # Extra skill sources, equivalent to the old @OPENCODE_CONFIG_DIR@ paths.
  # git-commit is deployed here by agent-skills (dotagents); final-review is
  # expected at the same location.
  omoSkills = {
    skills.sources = [
      "${configDir}/skill/final-review"
      "${configDir}/skill/git-commit"
    ];
  };

  opencodeHarness = lib.recursiveUpdate (lib.recursiveUpdate opencodeBase omoSkills) config.packs.opencode.omoOverrides;

  omoConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/omo.schema.json";
    "[opencode]" = opencodeHarness;
    "[senpi]" = senpiBase;
    # Keep the unification migration marker/history so the plugin never
    # re-runs legacy oh-my-openagent.json migrations over this managed file.
    legacy_migrations = {
      "${config.xdg.configHome}/opencode-go/oh-my-openagent.json" = [
        "model-version:openai/gpt-5.3-codex->openai/gpt-5.4"
        "model-version:openai/gpt-5.4->openai/gpt-5.5"
      ];
    };
    # Pin both migration markers: senpi-base.nix and opencode-base.nix are
    # already in the post-reasoning-unification format, and re-running the
    # migration would just rewrite the managed file at runtime.
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
