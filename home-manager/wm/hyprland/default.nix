{
  pkgs,
  inputs,
  system,
  ...
}:
{
  imports = [
    # ./eww
    ./qt
    ./rofi
    ./waybar
    ./wlogout
    # ./dunst.nix
    ./gtk.nix
    ./key-bindings.nix
    ./settings.nix
    ./swww.nix
    ./hypridle.nix
    ./hyprlock.nix
    #./hyprpanel.nix
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
    pamixer # pulseaudio mixer
    playerctl # media player control
    wayvnc # vnc server
    wev # key event watcher
    wireplumber # screens sharing
    wf-recorder # screen recorder
    wl-clipboard # clipboard manager
    cliphist # clipboard history
    polkit
    inputs.hyprpolkitagent.packages.${system}.hyprpolkitagent # password prompt
    # libsForQt5.polkit-kde-agent # password prompt(kde)
    libsecret # keyring
    networkmanagerapplet # network manager gui
  ];

  xdg.userDirs.createDirectories = true;
  services = {
    gnome-keyring.enable = true;
    kdeconnect.indicator = true;
  };
}
