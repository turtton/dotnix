{ pkgs, hostPlatform, ... }:
{
  imports =
    (
      if hostPlatform.isLinux then
        [
          ./fcitx
          ./libskk
          ./chat.nix
          ./document.nix
          ./image.nix
          ./kdeconnect.nix
          ./keybase.nix
        ]
      else
        [ ]
    )
    ++ [
      ./browser.nix
      ./media.nix
    ];

  home.packages =
    with pkgs;
    lib.optionals hostPlatform.isDarwin [
      raycast
    ]
    ++ lib.optionals hostPlatform.isLinux [
      mission-center # system monitor
      kdePackages.filelight # disk usage pie chart
    ];
}
