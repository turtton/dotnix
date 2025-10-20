{ pkgs, config, ... }:
let
  isEnabled = config.wayland.windowManager.hyprland.enable;
in
{
  wayland.windowManager.hyprland.settings = pkgs.lib.optionalAttrs isEnabled {
    bind = [
      "$mainMod, V, exec, noctalia-shell ipc call launcher clipboard"
      "$mainMod, d, exec, noctalia-shell ipc call launcher toggle"
      "$mainMod SHIFT, d, exec, noctalia-shell ipc call launcher calculator"
      # TODO: Add emoji Picker
      # "$mainMod, period, exec, bemoji"
    ];
  };
}
