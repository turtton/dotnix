{ pkgs, lib, ... }:
let
  settings = {
    model = "opus[1m]";
    language = "Japanese";
    tui = "fullscreen";
    autoCompactEnabled = true;
    teammateMode = "in-process";
    skipDangerousModePermissionPrompt = true;
    env = {
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    };
    statusLine = {
      type = "command";
      command = "bun x ccusage statusline";
      padding = 0;
    };
    enabledPlugins = {
      "review-gate@review-gate-marketplace" = true;
      "plan-reviewer@review-gate-marketplace" = true;
    };
    extraKnownMarketplaces = {
      review-gate-marketplace.source = {
        source = "github";
        repo = "turtton/claude-plugins";
      };
    };
  };
  settingsFile = (pkgs.formats.json { }).generate "claude-code-settings.json" settings;
in
{
  programs.claude-code = {
    enable = true;
    context = ./CLAUDE.md;
  };

  # Claude Code writes settings.json at runtime (/config, /effort, plugin state), so it must stay a
  # regular file. Top-level keys declared here replace the runtime values on every switch.
  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeSettings="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    claudeSettingsTmp=$(mktemp "$claudeSettings.XXXXXX")
    if [[ -f $claudeSettings ]]; then
      ${lib.getExe pkgs.jq} -s '.[0] + .[1]' "$claudeSettings" ${settingsFile} > "$claudeSettingsTmp"
    else
      cat ${settingsFile} > "$claudeSettingsTmp"
    fi
    chmod 600 "$claudeSettingsTmp"
    run mv "$claudeSettingsTmp" "$claudeSettings"
  '';
}
