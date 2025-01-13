{ pkgs, ... }: {
  home.packages = (with pkgs; [
    mpv
    tauon
    spotify
    yt-dlp
  ]) ++ pkgs.lib.optionals pkgs.hostPlatform.isLinux [
    pkgs.vlc
    pkgs.kdenlive
  ];
  programs.obs-studio.enable = true;
}
