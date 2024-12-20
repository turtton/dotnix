{ lib, ... }: {
  imports = [
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/dev
    (import ./../../home-manager/cli/git.nix { userName = "turtton"; userEmail = "top.gear7509@turtton.net"; signingKey = "8152FC5D0B5A76E1"; })
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/shared
    ./../../home-manager/gui/dev
    ./../../home-manager/gui/term/alacritty.nix
    ./../../home-manager/gui/filemanager/dolphin
    ./../../home-manager/wm/hyprland
  ];

  wayland.windowManager.hyprland.settings = {
    # check `hyprctl monitors all`
    monitor = [
      "eDP-1, 2240x1400@60, 0x0, 1.25"
      ",preferred,auto,1"
    ];
    input = {
      sensitivity = lib.mkForce 0.05;
      accel_profile = "flat";
      kb_layout = "us";
    };
    exec-once = [
      "1password"
      "KEYBASE_AUTOSTART=1 keybase-gui"
    ];
  };
}