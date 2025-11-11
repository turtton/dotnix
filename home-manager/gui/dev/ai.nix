{ pkgs, hostPlatform, ... }:
{
  home.packages =
    with pkgs;
    [
      claude-code
      gemini-cli
      codex
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
    ];
}
