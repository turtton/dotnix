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
  cgConfigDir = "${config.xdg.configHome}/opencode-cg";

  replaceConfigDir =
    dir: content: builtins.replaceStrings [ "@OPENCODE_CONFIG_DIR@" ] [ dir ] content;

  ohMyOpenagentMain = pkgs.writeText "oh-my-openagent.json" (
    replaceConfigDir configDir (builtins.readFile ./oh-my-openagent.json)
  );

  ohMyOpenagentGo = pkgs.writeText "oh-my-openagent-go.json" (
    replaceConfigDir goConfigDir (builtins.readFile ./oh-my-openagent-go.json)
  );

  ohMyOpenagentCg = pkgs.writeText "oh-my-openagent-cg.json" (
    replaceConfigDir cgConfigDir (builtins.readFile ./oh-my-openagent-cg.json)
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

  home.shellAliases = {
    oc-go = "OPENCODE_CONFIG_DIR=${goConfigDir} opencode";
    oc-cg = "OPENCODE_CONFIG_DIR=${cgConfigDir} opencode";
  };

  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" "agent-skills" ] ''
    deploy_profile() {
      local profile_dir="$1"
      local config_jsonc="$2"
      local openagent_json="$3"
      local profile_name="$4"

      for f in opencode.jsonc oh-my-openagent.json AGENTS.md; do
        [ -f "$profile_dir/$f" ] && mv -f "$profile_dir/$f" "$profile_dir/$f.old"
      done

      mkdir -p "$profile_dir"

      cp -f "$config_jsonc" "$profile_dir/opencode.jsonc"
      cp -f "$openagent_json" "$profile_dir/oh-my-openagent.json"
      cp -f "${./AGENTS.md}" "$profile_dir/AGENTS.md"

      chmod u+w "$profile_dir/opencode.jsonc" "$profile_dir/oh-my-openagent.json" "$profile_dir/AGENTS.md"

      if [ "$profile_dir" != "${configDir}" ]; then
        if [ "$profile_name" = "cg" ]; then
          rm -f "$profile_dir/opencode.json"
        elif [ -f "${configDir}/opencode.json" ]; then
          # Copy generated provider definitions for profiles that keep external providers.
          cp -f "${configDir}/opencode.json" "$profile_dir/opencode.json"
          chmod u+w "$profile_dir/opencode.json"
        else
          rm -f "$profile_dir/opencode.json"
          echo "WARNING: ${configDir}/opencode.json not found. cursor-acp provider unavailable in $profile_name profile." >&2
          echo "Run 'opencode' (main profile) first to generate it via the cursor-acp plugin." >&2
        fi

        # Mirror skills from main profile (deployed by agent-skills) to alternate profiles.
        if [ -d "${configDir}/skill" ]; then
          mkdir -p "$profile_dir/skill"
          ${pkgs.rsync}/bin/rsync -aL --delete "${configDir}/skill/" "$profile_dir/skill/"
        else
          rm -rf "$profile_dir/skill"
        fi

        [ -d "$profile_dir/skill" ] && chmod -R u+w "$profile_dir/skill"
      fi
    }

    deploy_profile "${configDir}" "${./opencode.jsonc}" "${ohMyOpenagentMain}" "main"
    deploy_profile "${goConfigDir}" "${./opencode-go.jsonc}" "${ohMyOpenagentGo}" "go"
    deploy_profile "${cgConfigDir}" "${./opencode-cg.jsonc}" "${ohMyOpenagentCg}" "cg"
  '';
}
