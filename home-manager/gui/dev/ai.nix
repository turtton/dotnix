{
  pkgs,
  lib,
  hostPlatform,
  ...
}:
{
  home.packages =
    with pkgs;
    lib.optionals hostPlatform.isLinux [
      claude-desktop
    ];
}
