{ pkgs, ... }:
{
  programs.plasma = {
    enable = true;

    workspace = {
      clickItemTo = "select";
      lookAndFeel = "Jolly-Global";
      cursorTheme = "breeze_cursors";
      iconTheme = "BeautyLine";
    };
  };
  home = {
    file = {
      "plasma-org.kde.plasma.desktop-appletsrc" = {
        target = ".config/plasma-org.kde.plasma.desktop-appletsrc";
        source = ./plasma-org.kde.plasma.desktop-appletsrc;
      };
    };
    packages = with pkgs; {
      libsForQt5.bismuth # Tiling extension
    }
  };
}
