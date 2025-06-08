{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      lmstudio
      claude-code
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
    ];
}
