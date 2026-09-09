{
  pkgs,
  lib,
  config,
  inputs,
  system,
  isHomeManager,
  hostPlatform,
  ...
}:
let
  cfg = config.packs.noctalia;
  hyprlandEnabled = config.wayland.windowManager.hyprland.enable or false;
in
{
  imports =
    lib.optionals (isHomeManager && hostPlatform.isLinux) [
      inputs.noctalia.homeModules.default
    ]
    ++ lib.optionals (!isHomeManager && hostPlatform.isLinux) [
      inputs.noctalia.nixosModules.default
    ];

  options.packs.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell (bar, launcher, lock screen)";
  };

  config = lib.mkIf cfg.enable (
    if !hostPlatform.isLinux then
      { }
    else if isHomeManager then
      lib.mkMerge [
        {
          home.packages = with pkgs; [
            inputs.noctalia.packages.${system}.default
            wl-clipboard
            cliphist
          ];
          programs.noctalia = {
            enable = true;
            settings = {
              bar.main = {
                # Keep the bar pinned to the per-host primary output; hosts enable it on their monitor.
                enabled = false;
                position = "left";
                capsule = false;
                start = [
                  "control-center"
                  "network"
                  "bluetooth"
                  "media"
                  "active_window"
                ];
                center = [ "workspaces" ];
                end = [
                  "tray"
                  "privacy"
                  "battery"
                  "volume"
                  "clock"
                  "notifications"
                ];
              };
              battery.warning_threshold = 20;
              widget.workspaces = {
                show_labels = false;
                labels_only_when_occupied = false;
                hide_when_empty = false;
              };
              dock.enabled = false;
              theme = {
                mode = "dark";
                source = "builtin";
                builtin = "Catppuccin";
              };
              wallpaper = {
                enabled = true;
                fill_mode = "crop";
                directory = "${pkgs.wallpaper-outerspace}";
              };
              shell = {
                avatar_path = "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake.png";
                corner_radius_scale = 0.2;
                clipboard_enabled = true;
                time_format = "{:%H:%M}";
              };
              location = {
                auto_locate = false;
                address = "Kyoto, Japan";
              };
            };
          };
        }
        # Hyprland-specific keybindings
        (lib.mkIf hyprlandEnabled {
          wayland.windowManager.hyprland.settings = {
            bind = [
              "$mainMod, V, exec, noctalia msg panel-toggle clipboard"
              "$mainMod, d, exec, noctalia msg panel-toggle launcher"
              "$mainMod SHIFT, d, exec, noctalia msg panel-toggle launcher /calc"
            ];
          };
        })
      ]
    else
      { }
  );
}
