{
  pkgs,
  lib,
  hostPlatform,
  isWsl,
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
        opencode-latest
        senpi
        cursor-cli
      ]
      ++ pkgs.lib.optionals (!isWsl) [
        opencode
      ]
      ++ pkgs.lib.optionals hostPlatform.isLinux [
        llm-agents.codex
        codex-latest
      ];
    sessionVariables = {
      CURSOR_AGENT_PATH = "${lib.getExe pkgs.cursor-cli}";
    };
  };
  programs.claude-code = {
    enable = true;
  };
}
