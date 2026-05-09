{ pkgs, hostPlatform, ... }:
{
  home.packages =
    with pkgs;
    [
      spotify
      yt-dlp
    ]
    ++ lib.optionals hostPlatform.isLinux [
      mpv
      tauon
      vlc
      kdePackages.kdenlive
      mixxx
    ];
  programs.obs-studio.enable = hostPlatform.isLinux;
}
