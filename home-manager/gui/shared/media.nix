{ pkgs, ... }: {
  home.packages = with pkgs; [
    mpv
    vlc
    spotify
    yt-dlp
    kdenlive
  ];
  programs.obs-studio.enable = true;
}
