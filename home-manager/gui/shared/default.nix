{ pkgs, hostPlatform, ... }: {
  imports =
    (if hostPlatform.isLinux then [
      ./fcitx
      ./libskk
      ./chat.nix
      ./document.nix
      ./image.nix
      ./kdeconnect.nix
      ./keybase.nix
    ] else [ ]) ++ [
      ./browser.nix
      ./media.nix
      ./bitwarden.nix
    ];

  home.packages = with pkgs; lib.optionals hostPlatform.isDarwin [
    raycast
    macskk
  ];
}
