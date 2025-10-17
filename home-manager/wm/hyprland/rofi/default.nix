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
  wayland.windowManager.hyprland.settings.bind = [
    "$mainMod, P, exec, ${pkgs.rofi-rbw-wayland}/bin/rofi-rbw"
    "$mainMod, V, exec, rofi -modi clipboard:${pkgs.cliphist}/bin/cliphist-rofi-img -show clipboard -show-icons -theme-str '##element-icon {size: 5ch; }'"
    "$mainMod, d, exec, rofi -show drun"
    "$mainMod, period, exec, bemoji"
  ];
}
