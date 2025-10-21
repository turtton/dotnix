{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      claude-code
      gemini-cli
      codex
      playwright-mcp
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
      jan
      # broken on darwin
      lmstudio
    ];
}
