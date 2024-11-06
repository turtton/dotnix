{ pkgs, ... }:
{
  home.packages = with pkgs.xfce; [
    thunar
    thunar-volman
    thunar-archive-plugin
  ];
}
