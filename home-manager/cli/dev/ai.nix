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
        rtk
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
