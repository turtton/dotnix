{ pkgs, ... }:
{
  home.packages = [
    pkgs.ghostty.terminfo
  ];
  programs.ghostty = {
    enable = true;
    installVimSyntax = true;
    settings = {
      theme = "Catppuccin Mocha";
      font-family = "Hack Nerd Font";
      font-size = 10;
      background-opacity = 0.7;
      background-blur = "macos-glass-clear";
      macos-titlebar-style = "transparent";
    };
  };
}
