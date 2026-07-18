{
  pkgs,
  lib,
  hostPlatform,
  ...
}:
{
  imports = [
    ./opencode
  ];
  home = {
    packages =
      with pkgs;
      [
        cursor-cli
        llm-agents.copilot-cli
      ]
      ++ pkgs.lib.optionals hostPlatform.isLinux [
        llm-agents.codex
        codex-latest
        llm-agents.cli-proxy-api
      ];
    sessionVariables = {
      CURSOR_AGENT_PATH = "${lib.getExe pkgs.cursor-cli}";
    };
  };
  systemd.user.services.cli-proxy-api = lib.mkIf hostPlatform.isLinux {
    Unit.Description = "CLI Proxy API (OpenAI/Gemini/Claude/Codex compatible proxy)";
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.llm-agents.cli-proxy-api} -config %h/.config/cli-proxy-api/config.yaml";
      Restart = "on-failure";
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
}
