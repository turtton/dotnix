{pkgs, ...}: {
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