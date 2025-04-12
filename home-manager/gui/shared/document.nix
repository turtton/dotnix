{ pkgs, ... }:
{
  home.packages = with pkgs; [
    obsidian
    typora
    evince
  ];
}
