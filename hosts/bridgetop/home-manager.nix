{
  imports = [
    ./plasma/plasma.nix
    ./plasma/plasma_generated.nix
    ./../../home-manager/cli/shared
    (import ./../../home-manager/cli/git.nix { userName = "turtton"; userEmail = "top.gear7509@turtton.net"; signingKey = "8152FC5D0B5A76E1"; })
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/shared
  ];

  home = rec {
    username = "bbridge";
    homeDirectory = "/home/${username}";
    stateVersion = "23.11";
  };
}
