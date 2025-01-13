{ pkgs, ... }: {
  imports = [
    ./browser.nix
    ./keybase.nix
    ./media.nix
  ] ++ pkgs.lib.optionals pkgs.hostPlatform.isLinux [
    ./fcitx
    ./libskk
    ./document.nix
    ./image.nix
    ./chat.nix
    ./kdeconnect.nix
  ];
}
