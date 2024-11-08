{ pkgs, ... }: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland.overrideAttrs (old: { plugins = [ pkgs.bemoji ]; });
    #	Refered: https://github.com/NeshHari/XMonad/blob/main/rofi/.config/rofi/config.rasi
    theme = ./rofi.rasi;
  };
}
