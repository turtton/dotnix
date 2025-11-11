{ pkgs, hostPlatform, ... }:
{
  home.packages =
    with pkgs;
    lib.optionals hostPlatform.isLinux [
      unityhub
      blender
    ];
}
