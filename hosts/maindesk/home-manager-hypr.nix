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
  ];

  wayland.windowManager.hyprland.settings = {
    # check `hyprctl monitors all`
    monitor = [
      "desc:ViewSonic Corporation VX2458-mhd VK0184700653, 1920x1080@144, 0x0, 1"
      "desc:BNQ BenQ GL2460 J6G05593SL0, 1920x1080@60, 1920x0, 1"
      "desc:Dell Inc. DELL E2210H J232R9A5091L, 1920x1080@60, -1920x0, 1"
      ",preferred,auto,1"
    ];
    input = {
      sensitivity = lib.mkForce "-0.45";
      accel_profile = "flat";
      kb_layout = "us";
    };
    exec-once = [
      "[workspace 1 silent] bitwarden"
      "[workspace 2 silent] vesktop"
      "steam -silent"
      "KEYBASE_AUTOSTART=1 keybase-gui"
    ];
  };
}
