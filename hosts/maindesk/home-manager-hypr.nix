{ lib, ... }: {
  imports = [
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/dev
    (import ./../../home-manager/cli/git.nix { userName = "turtton"; userEmail = "top.gear7509@turtton.net"; signingKey = "8152FC5D0B5A76E1"; })
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
      "DP-1, 2560x1440@165, 1920x0, 1"
      "DP-2, 1920x1080@144, 0x0, 1"
      ",preferred,auto,1"
    ];
    input = {
      sensitivity = lib.mkForce 0.2;
      kb_layout = "us";
    };
  };
}
