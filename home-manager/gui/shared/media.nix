{ pkgs, ... }: {
  home.packages = with pkgs; [
    mpv
    vlc
    spotify
  ];
  programs.obs-studio.enable = true;
}
