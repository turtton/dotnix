{ pkgs, ... }: {
  home.packages = with pkgs; [
    hyprpanel # status bar and notification daemon
    networkmanager
    gnome-bluetooth
    libgtop
    bluez
    bluez-tools
    brightnessctl
    gpu-screen-recorder
    gcolor3
    grimblast
    btop
    jq
    vulnix
    pavucontrol
    pulseaudio
  ];
  home.file.".cache/ags/hyprpanel/options.json".text = builtins.toJSON {
    "bar.customModules.updates.pollingInterval" = 1440000;
    "theme.bar.floating" = false;
    "theme.bar.buttons.enableBorders" = true;
    "theme.bar.transparent" = true;
    "theme.font.size" = "14px";
    "menus.clock.time.military" = true;
    "menus.clock.time.hideSeconds" = false;
    "bar.clock.format" = "%y/%m/%d  %H:%M";
    "bar.media.show_active_only" = true;
    "bar.notifications.show_total" = false;
    "theme.bar.buttons.modules.ram.enableBorder" = false;
    "bar.launcher.autoDetectIcon" = true;
    "bar.layouts" =
      let
        layout = {
          "left" = [
            "dashboard"
            "workspaces"
            "windowtitle"
            "updates"
            "storage"
            "battery"
          ];
          "middle" = [
            "media"
          ];
          "right" = [
            "cpu"
            "ram"
            "volume"
            "network"
            "bluetooth"
            "battery"
            "systray"
            "clock"
            "notifications"
          ];
        };
        none = {
          "left" = [ ];
          "middle" = [ ];
          "right" = [ ];
        };
      in
      {
        "0" = layout;
        "1" = none;
        "2" = layout;
        "3" = none;
      };
    "menus.dashboard.controls.enabled" = false;
    "menus.dashboard.shortcuts.enabled" = true;
    "menus.clock.weather.enabled" = false;
    "menus.dashboard.shortcuts.right.shortcut1.command" = "gcolor3";
    "menus.media.displayTime" = true;
    "bar.customModules.updates.updateCommand" = "jq '[.[].cvssv3_basescore | to_entries | add | select(.value > 5)] | length' <<< $(vulnix -S --json)";
    "bar.customModules.updates.icon" = "󰋼";
    "bar.volume.rightClick" = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
    "bar.volume.middleClick" = "pavucontrol";
    "bar.media.format" = "{title}";
  };
}
