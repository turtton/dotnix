{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      lmstudio
    ]
    ++ lib.optionals hostPlatform.isLinux [
      claude-desktop
      jan
    ];
}
