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
        codex-latest
        opencode-latest
        llm-agents.codex
        rtk
        senpi
        cursor-cli
      ]
      ++ pkgs.lib.optionals (!isWsl) [
        opencode
      ];
    activation.rtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.getExe pkgs.rtk} init -g --opencode
    '';
    sessionVariables = {
      CURSOR_AGENT_PATH = "${lib.getExe pkgs.cursor-cli}";
    };
  };
  programs.claude-code = {
    enable = true;
  };
}
