{ lib, ... }: {
  imports = [
    # ./plasma/plasma.nix
    # ./plasma/plasma_generated.nix
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/shared
    ./../../home-manager/gui/term/alacritty.nix
    ./../../home-manager/gui/filemanager/thunar.nix
    ./../../home-manager/wm/hyprland
    # ./../../home-manager/gui/game
  ];

  wayland.windowManager.hyprland.settings = {
    # hyprctl monitors all
    monitor = [
      "Virtual-1, 1280x1024, 0x0, 1"
      ", preferred, auto, 1"
    ];
    workspace = [
      "1, monitor:Virtual-1"
      "2, monitor:Virtual-1"
      "3, monitor:Virtual-1"
      "4, monitor:Virtual-1"
      "5, monitor:Virtual-1"
      "6, monitor:Virtual-1"
      "7, monitor:Virtual-1"
      "8, monitor:Virtual-1"
      "9, monitor:Virtual-1"
    ];
    input = {
      sensitivity = lib.mkForce 0.2;
      kb_layout = "us";
    };
  };
}
