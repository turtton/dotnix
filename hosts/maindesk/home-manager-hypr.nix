{ lib, ... }:
{
  imports = [
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/dev
    (import ./../../home-manager/cli/git.nix {
      userName = "turtton";
      userEmail = "top.gear7509@turtton.net";
      signingKey = "8152FC5D0B5A76E1";
    })
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/shared
    ./../../home-manager/gui/dev
    ./../../home-manager/gui/game
    ./../../home-manager/gui/term/alacritty.nix
    ./../../home-manager/gui/filemanager/dolphin
    ./../../home-manager/wm/hyprland
    ./../../home-manager/wm/hyprland/nvidia.nix
  ];

  wayland.windowManager.hyprland.settings = {
    # check `hyprctl monitors all`
    monitor = [
      "DP-1, 1920x1080@144, 0x0, 1"
      "HDMI-A-1, 1920x1080@60, 1920x0, 1"
      "DVI-D-1, 1920x1080@60, -1900x-1080, 1"
      ",preferred,auto,1"
    ];
    input = {
      sensitivity = lib.mkForce "-0.45";
      accel_profile = "flat";
      kb_layout = "us";
    };
    exec-once = [
      "bitwarden"
      "[workspace 1 silent] vesktop"
      "steam -silent"
      "KEYBASE_AUTOSTART=1 keybase-gui"
    ];
  };
}
