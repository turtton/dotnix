{ lib, pkgs, ... }: {
  wayland.windowManager.hyprland.settings = {
    "plugin:split-monitor-workspaces:count" = 5;
    env = [
      # "GTK_IM_MODULE, fcitx"
      # "QT_IM_MODULE, wayland;fcitx"
      "XMODIFIERS, @im=fcitx"
      "QT_QPA_PLATFORM,wayland"
      "QT_QPA_PLATFORMTHEME,qt5ct"
      "QT_STYLE_OVERRIDE,kvantum"
      "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
      "NIXOS_OZONE_WL,1" # for chromium based system to force wayland
    ];
    exec-once = [
      "hyprlock"
      "swww init && swww img ${pkgs.wallpaper-springcity}/wall.png"
      "${./eww/config/scripts/start.sh}"
      #"waybar"
      ''${pkgs.hyprpanel}/bin/hyprpanel -r "useTheme('${pkgs.hyprpanel-tokyonight}/tokyo_night.json')"''
      "fcitx5 -D"
      # "hypr-helper start"
      "systemctl --user start hyprpolkitagent"
      "wl-paste --watch cliphist store"
    ];
    windowrulev2 = [
      "pseudo noblur, class:^(fcitx)(.*)$"
      "noblur class:(wofi)"
      "opaque, class:^(discord)$"
      "opaque, class:^(vesktop)$"
      "opaque, class:^(Slack)$"
      "opaque, class:^(vivaldi-.*)$"
      "opaque, class:^(chromium-.*)$"
      "opaque, class:^(firefox)$"
      "opaque, class:^(jetbrains-.*)$"
      "opaque, class:^(swappy)$"
      "suppressevent maximize, class:.*"
    ];
    input = {
      repeat_delay = 300;
      repeat_rate = 30;
      follow_mouse = 1;
      sensitivity = lib.mkDefault (-0.5); # -1.0 - 1.0, 0 means no modification.
    };
    general = {
      gaps_in = 5;
      gaps_out = 5;
      border_size = 2;
      "col.inactive_border" = "rgb(#222436)";
      "col.active_border" = "rgb(#82aaff)";
      resize_on_border = true;
    };
    decoration = {
      rounding = 10;
      active_opacity = 0.8;
      inactive_opacity = 0.8;
      blur = {
        enabled = true;
        size = 3;
        passes = 1;
        xray = true;
        ignore_opacity = true;
        new_optimizations = true;
      };
    };
    animations = {
      bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
      animation = [
        "windows, 1, 4, myBezier, slide"
        "border, 1, 5, default"
        "fade, 1, 5, default"
        "workspaces, 1, 6, default"
      ];
    };
    dwindle = {
      pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
      preserve_split = true; # you probably want this
    };
    misc = {
      disable_hyprland_logo = true;
    };
    # master = {
    #   new_status = "master";
    # };
  };
}
