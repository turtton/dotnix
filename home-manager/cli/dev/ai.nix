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
  home.packages = with pkgs; [
    codex-latest
    opencode-latest
    llm-agents.codex
    opencode
    rtk
  ];
  programs.claude-code = {
    enable = true;
  };
  home.activation.rtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.getExe pkgs.rtk} init -g --opencode
  '';
}
