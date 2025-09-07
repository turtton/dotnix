{ lib, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    "plugin:split-monitor-workspaces:count" = 8;
    env = [
      # "GTK_IM_MODULE, fcitx"
      # "QT_IM_MODULE, wayland;fcitx"
      "XMODIFIERS, @im=fcitx"
      "QT_QPA_PLATFORM,wayland"
      "QT_QPA_PLATFORMTHEME,qt5ct"
      "QT_STYLE_OVERRIDE,kvantum"
      "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
      "NIXOS_OZONE_WL,1" # for chromium based system to force wayland
      "GIO_MODULE_DIR, ${pkgs.glib-networking}/lib/gio/modules/" # Workaround for wry https://github.com/tauri-apps/wry/issues/605
    ];
    exec-once = [
      "hyprlock"
      "fcitx5 -D"
      # "hypr-helper start"
      "systemctl --user start hyprpolkitagent"
      #"systemctl --user start plasma-polkit-agent"
      "wl-paste --watch cliphist store"
      "${pkgs.cliphist}/bin/cliphist wipe"
      "${pkgs.gitify}/bin/gitify"
    ];
    windowrulev2 =
      let
        opaqueClasses = [
          "discord"
          "vesktop"
          "Slack"
          "zoom"
          "vivaldi"
          "chromium"
          "zen"
          "firefox"
          "jetbrains"
          "swappy"
          "Minecraft"
          "com.obsproject.Studio"
          "krita"
          "factorio"
          "code"
          ".*\.exe"
        ];
      in
      map (c: "opaque, class:^(${c}.*)$") opaqueClasses
      ++ [
        "pseudo noblur, class:^(fcitx)(.*)$"
        "noblur class:(wofi)"
        "opaque, initialTitle:^(Picture in picture)(.*)$"
        "opaque, initialTitle:^(.* on QEMU/KVM)$"
        "float, class:^(org.kde.kdeconnect.daemon)(.*)$"
        "suppressevent maximize, class:.*"
        # https://github.com/hyprwm/Hyprland/issues/8395#issuecomment-2578588978
        "noinitialfocus,class:^jetbrains-.*$,title:^$,floating:1"
        # Disable opacity for Remmina connected windows
        "opaque, class:org.remmina.Remmina,title:^(!?Remmina$)"
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
      "col.inactive_border" = "0xff222436";
      "col.active_border" = "0xff82aaff";
      resize_on_border = true;
    };
    decoration = {
      rounding = 10;
      active_opacity = 0.8;
      inactive_opacity = 0.8;
      blur = {
        enabled = true;
        size = 6;
        passes = 1;
        xray = false;
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
      focus_on_activate = true;
      enable_anr_dialog = false;
    };
    xwayland = {
      use_nearest_neighbor = false;
      force_zero_scaling = true;
    };
    # render.explicit_sync = 0;
    # master = {
    #   new_status = "master";
    # };
  };
}
