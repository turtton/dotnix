{
  imports = [
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/dev
    (import ./../../home-manager/cli/git.nix {
      userName = "turtton";
      userEmail = "top.gear7509@turtton.net";
      signingKey = "~/.ssh/id_ed25519.pub";
      signingType = "ssh";
    })
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/dev
    ./../../home-manager/gui/shared
    ./../../home-manager/gui/term/alacritty.nix
    ./../../home-manager/gui/term/ghostty.nix
    # ./../../home-manager/wm/aerospace
  ];
}
