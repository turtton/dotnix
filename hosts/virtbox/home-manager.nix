{pkgs, ...}: {
  imports = [
    ./../../apps.nix
    ./../../dev.nix
    ./../../direenv.nix
    ./../../git.nix
    ./plasma/plasma.nix
    ./plasma/plasma_generated.nix
    ./../../starship.nix
    ./../../zsh.nix
  ];

  home.packages = with pkgs; [
    bat
    jdk21
  ];
}