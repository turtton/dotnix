{ pkgs, ... }: {
  home.packages = with pkgs; [
    spotify
    yt-dlp
  ]
  ++ lib.optionals hostPlatform.isLinux [
    mpv
    tauon
    vlc
    kdePackages.kdenlive
  ];
  programs.obs-studio.enable = pkgs.hostPlatform.isLinux;
}
