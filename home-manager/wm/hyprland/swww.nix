{ pkgs, ... }:
{
  services.swww.enable = true;
  wayland.windowManager.hyprland.settings.exec-once = [
    "swww img ${pkgs.wallpaper-springcity}/wall.png"
  ];
}
