{
  imports = [
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/dev
    (import ./../../home-manager/cli/git.nix { userName = "turtton"; userEmail = "top.gear7509@turtton.net"; signingKey = "8152FC5D0B5A76E1"; })
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/dev
    ./../../home-manager/gui/shared/browser.nix
    ./../../home-manager/gui/shared/keybase.nix
    ./../../home-manager/gui/shared/media.nix
    ./../../home-manager/gui/term/alacritty.nix
  ];
}
