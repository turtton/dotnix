{ pkgs, inputs, system, ... }: {
  imports = [
    ./eww
    ./qt
    ./rofi
    # ./waybar
    # ./dunst.nix
    ./gtk.nix
    ./key-bindings.nix
    ./settings.nix
    ./hyprlock.nix
    ./hyprpanel.nix
    ./utilapp.nix
    #./wofi.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    plugins = [
      inputs.split-monitor-workspaces.packages.${system}.split-monitor-workspaces
    ];
    package = inputs.hyprland.packages.${system}.hyprland;
  };

  home.packages = with pkgs; [
    brightnessctl # screen brightness
    grimblast # screenshot
    swappy # image editor for screenshots
    zenity # create screenshot save dialog
    hyprpicker # color picker
    bemoji # emoji picker
    pamixer # pulseaudio mixer
    playerctl # media player control
    swww # wallpaper
    wayvnc # vnc server
    wev # key event watcher
    wf-recorder # screen recorder
    wl-clipboard # clipboard manager
    cliphist # clipboard history
    polkit
    hyprpolkitagent # password prompt
    libsecret # keyring
  ];

  xdg.userDirs.createDirectories = true;
  services = {
    gnome-keyring.enable = true;
  };
}
