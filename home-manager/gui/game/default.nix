{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # minecraft-launcher marked boroken https://github.com/NixOS/nixpkgs/pull/299645
    # minecraft
    blockbench-electron # it is not game, but related to minecraft
    prismlauncher
    lunar-client
    lutris
    osu-lazer
  ];
}
