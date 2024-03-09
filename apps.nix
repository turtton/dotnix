{pkgs, ...}: {
  programs.obs-studio.enable = true;

  home.packages = with pkgs; [
    discord
    discord-ptb
    vesktop
    slack
    spotify
  ];
}