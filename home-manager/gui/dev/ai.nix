{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      lmstudio
      gemini-cli
      playwright-mcp
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
      jan
    ];
}
