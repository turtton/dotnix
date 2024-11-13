{ pkgs, ... }: {
  home.packages = with pkgs; [
    libsForQt5.dolphin
    libsForQt5.dolphin-plugins
    jetbrains-dolphin-qt5
    ark
  ];
  xdg.dataFile."dolphin" = {
    source = ./share;
    recursive = true;
  };
}
