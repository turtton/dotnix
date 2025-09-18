{ pkgs, ... }:
{
  imports = [
    ./bemoji.nix
  ];
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    #	Refered: https://github.com/NeshHari/XMonad/blob/main/rofi/.config/rofi/config.rasi
    theme = ./rofi.rasi;
  };
}
