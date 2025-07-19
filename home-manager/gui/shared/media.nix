{ pkgs, pkgs-staging-next, ... }:
{
  home.packages =
    with pkgs;
    [
      spotify
      yt-dlp
    ]
    ++ lib.optionals hostPlatform.isLinux [
      mpv
      # https://nixpkgs-tracker.ocfox.me/?pr=424658
      pkgs-staging-next.tauon
      vlc
      kdePackages.kdenlive
    ];
  programs.obs-studio.enable = pkgs.hostPlatform.isLinux;
}
