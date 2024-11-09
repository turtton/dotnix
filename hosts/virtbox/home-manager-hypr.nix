{ lib, ... }: {
  imports = [
    # ./plasma/plasma.nix
    # ./plasma/plasma_generated.nix
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/shell/zsh
    # ./../../home-manager/gui/shared
    ./../../home-manager/gui/shared/fcitx
    ./../../home-manager/gui/shared/libskk
    ./../../home-manager/gui/term/alacritty.nix
    ./../../home-manager/gui/filemanager/nautilus.nix
    ./../../home-manager/wm/hyprland
    # ./../../home-manager/gui/game
  ];

  wayland.windowManager.hyprland.settings = {
    # hyprctl monitors all
    monitor = [
      "Virtual-1, 1600x900, 0x0, 1"
      ", preferred, auto, 1"
    ];
    input = {
      sensitivity = lib.mkForce 0.2;
      kb_layout = "us";
    };
  };
}
