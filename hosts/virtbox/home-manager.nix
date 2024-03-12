{
  imports = [
    ./plasma/plasma.nix
    ./plasma/plasma_generated.nix
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/shared
    ./../../home-manager/gui/game
  ];

  services.keybase.enable = true;
}