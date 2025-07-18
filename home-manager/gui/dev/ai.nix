{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      lmstudio
      gemini-cli
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
      jan
    ];
}
