{ pkgs, ... }: {
  home.packages = with pkgs; [
    hyprpanel # status bar and notification daemon
    gpu-screen-recorder
    hyprpicker
    grimblast
  ];
  home.file.".cache/ags/hyprpanel/options.json".source = ./hyprpanel_config.json;
}
