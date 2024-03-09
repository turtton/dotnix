{pkgs, ...}: {
  imports = [
    ./apps.nix
    ./dev.nix
    ./direenv.nix
    ./git.nix
    ./starship.nix
    ./zsh.nix
  ];
  home = rec {
    username = "turtton";
    homeDirectory = "/home/${username}";
    stateVersion = "23.11";
    packages = with pkgs; [
      bat
    ];
  };
  programs.home-manager.enable = true;
}