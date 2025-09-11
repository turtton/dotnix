{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      lmstudio
      claude-code
      gemini-cli
      codex
      playwright-mcp
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
      jan
    ];
}
