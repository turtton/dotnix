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
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "${pkgs.dolphin}/share/applications/org.kde.dolphin.desktop" ];
  };
}
