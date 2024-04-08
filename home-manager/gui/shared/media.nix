{ pkgs, ... }: {
  home.packages = with pkgs; [
    mpv
    vlc
    spotify
    yt-dlp
  ];
  programs.obs-studio.enable = true;
}
