{
  config,
  pkgs,
  lib,
  hostPlatform,
  ...
}:
let
  claudeSandboxSettings = pkgs.writeText "claude-code-settings.json" (
    builtins.toJSON {
      allowManagedPermissionRulesOnly = true;
      sandbox = {
        enabled = true;
        failIfUnavailable = true;
        autoAllowBashIfSandboxed = true;
        allowUnsandboxedCommands = false;
        excludedCommands = [ ];
        network = {
          allowUnixSockets = [ ];
          allowAllUnixSockets = false;
          allowLocalBinding = false;
          allowedDomains = [ ];
          httpProxyPort = null;
          socksProxyPort = null;
        };
        enableWeakerNestedSandbox = false;
      };
    }
  );
in
{
  imports = [
    ./opencode
  ];
  home = {
    packages =
      with pkgs;
      [
        cursor-cli
      ]
      ++ pkgs.lib.optionals hostPlatform.isLinux [
        llm-agents.codex
        codex-latest
      ];
    sessionVariables = {
      CURSOR_AGENT_PATH = "${lib.getExe pkgs.cursor-cli}";
    };
  };
  programs = {
    claude-code = {
      enable = true;
    };
    codexDesktopLinux = {
      enable = hostPlatform.isLinux;
      computerUseUi.enable = true;
      remoteMobileControl.enable = true;
      remoteControl.enable = true;
    };
  };

  home.activation.claudeCodeSandboxSettings = lib.mkIf hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      install_claude_settings() {
        local settings_dir="$1"

        [ -n "$settings_dir" ] || return 0
        mkdir -p "$settings_dir"

        if [ -f "$settings_dir/settings.json" ] && ${pkgs.jq}/bin/jq -e type "$settings_dir/settings.json" >/dev/null; then
          tmp_settings="$(${pkgs.coreutils}/bin/mktemp "$settings_dir/settings.json.XXXXXX")"
          ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings_dir/settings.json" "${claudeSandboxSettings}" >"$tmp_settings"
          mv -f "$tmp_settings" "$settings_dir/settings.json"
        else
          cp -f "${claudeSandboxSettings}" "$settings_dir/settings.json"
        fi

        chmod u+w "$settings_dir/settings.json"
      }

      install_claude_settings "${config.home.homeDirectory}/.claude"

      profiles_file="${config.xdg.configHome}/profile-claude-code/profiles.conf"
      if [ -f "$profiles_file" ]; then
        while IFS='|' read -r _ profile_path; do
          install_claude_settings "$profile_path"
        done <"$profiles_file"
      fi
    ''
  );
}
