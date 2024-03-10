{pkgs, ...}: {
  imports = [
    ./../../apps.nix
    ./../../dev.nix
    ./../../direenv.nix
    ./../../git.nix
    ./../../plasma.nix
    ./../../plasma_generated.nix
    ./../../starship.nix
    ./../../zsh.nix
  ];

  home.packages = with pkgs; [
    bat
    jdk21
  ];
}