{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland.overrideAttrs(old: { plugins = [ pkgs.rofi-emoji ]; });
    #	Refered: https://github.com/NeshHari/XMonad/blob/main/rofi/.config/rofi/config.rasi
    theme = ./rofi.rasi;
  };
}
