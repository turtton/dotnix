{
  pkgs,
  lib,
  config,
  isHomeManager,
  ...
}:
let
  cfg = config.packs.bemoji;
  hyprlandEnabled = config.wayland.windowManager.hyprland.enable or false;
  niriEnabled = config.programs.niri.enable or false;
in
{
  options.packs.bemoji.enable = lib.mkEnableOption "Enable bemoji emoji picker";

  config = lib.mkIf cfg.enable (
    if isHomeManager then
      {
        packs.rofi.enable = true;

        home.packages = [ pkgs.bemoji ];

        home.sessionVariables.BEMOJI_PICKER_CMD = "rofi -dmenu -i -p emoji";

        xdg.dataFile."bemoji/shortcodes.txt".source = ./bemoji.txt;

        # Hyprland keybinding
        wayland.windowManager.hyprland.settings = lib.mkIf hyprlandEnabled {
          bind = [ "$mainMod, period, exec, bemoji" ];
        };

        # Niri keybinding
        programs.niri.settings.binds = lib.mkIf niriEnabled {
          "Mod+Period".action.spawn = [ "bemoji" ];
        };
      }
    else
      { }
  );
}
