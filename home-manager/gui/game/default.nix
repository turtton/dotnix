{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # minecraft-launcher marked boroken https://github.com/NixOS/nixpkgs/pull/299645
    # minecraft
    blockbench # it is not game, but related to minecraft
    blockbench_4 # For animated java plugin
    prismlauncher
    lunar-client
    lutris
    osu-lazer
    r2modman

    # utilities
    gamemode
    mangohud
    gamescope

    alcom # VCC Alternative
  ];
}
