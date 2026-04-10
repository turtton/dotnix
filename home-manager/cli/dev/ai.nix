{
  pkgs,
  lib,
  hostPlatform,
  ...
}:
{
  home.packages = with pkgs; [
    codex-latest
    opencode-latest
    llm-agents.codex
    opencode
  ];
  programs.claude-code = {
    enable = true;
  };
}
