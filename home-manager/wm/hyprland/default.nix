{ pkgs, inputs, ... }: {
  imports = [
    ./dunst.nix
    ./key-bindings.nix
    ./settings.nix
    ./wofi.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
  };

  home.packages = with pkgs; [
    brightnessctl # screen brightness
    grimblast # screenshot
    hyprpicker # color picker
    pamixer # pulseaudio mixer
    playerctl # media player control
    swww # wallpaper
    wayvnc # vnc server
    wev # key event watcher
    wf-recorder # screen recorder
    wl-clipboard # clipboard manager
  ];
}