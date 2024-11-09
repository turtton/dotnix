{ pkgs, ... }: {
  home.packages = with pkgs; [
    hyprpanel # status bar and notification daemon
    networkmanager
    gnome-bluetooth
    libgtop
    bluez
    bluez-tools
    brightnessctl
    gpu-screen-recorder
    hyprpicker
    grimblast
    btop
  ];
  home.file.".cache/ags/hyprpanel/options.json".source = ./hyprpanel_config.json;
}
