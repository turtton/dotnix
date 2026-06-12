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
