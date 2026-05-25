{ pkgs, hostPlatform, ... }:
{
  home.packages =
    with pkgs;
    [
      yt-dlp
    ]
    ++ lib.optionals hostPlatform.isLinux [
      spotify # spotify works in darwin but not for me
      mpv
      tauon
      vlc
      kdePackages.kdenlive
      mixxx
    ];
  programs.obs-studio.enable = hostPlatform.isLinux;
}
