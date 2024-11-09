{ pkgs, ... }: {
  home.packages = with pkgs; [
    mpv
    vlc
    tauon
    spotify
    yt-dlp
    kdenlive
  ];
  programs.obs-studio.enable = true;
}
