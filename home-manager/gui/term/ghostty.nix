{ pkgs, hostPlatform, ... }:
let
  ghostty = if hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
in
{
  home.packages = [
    ghostty.terminfo
  ];
  programs.ghostty = {
    enable = true;
    package = ghostty;
    installVimSyntax = true;
    settings = {
      theme = "Catppuccin Mocha";
      font-family = "Hack Nerd Font";
      font-size = 10;
      background-opacity = 0.7;
      background-blur = "macos-glass-clear";
      macos-titlebar-style = "transparent";
      window-save-state = "never";
      quit-after-last-window-closed = true;
    };
  };
}
