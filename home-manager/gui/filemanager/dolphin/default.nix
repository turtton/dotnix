{ pkgs, ... }: {
  home.packages = with pkgs; [
    libsForQt5.dolphin
    libsForQt5.dolphin-plugins
    libsForQt5.kio-extras
    jetbrains-dolphin-qt5
    kdePackages.ark
  ];
  xdg.dataFile."dolphin" = {
    source = ./share;
    recursive = true;
  };
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "${pkgs.dolphin}/share/applications/org.kde.dolphin.desktop" ];
  };
}
