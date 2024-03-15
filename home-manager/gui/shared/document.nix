{pkgs, ...} : {
  home.packages = with pkgs; [
    obsidian
    typora
    libsForQt5.shelf
    libreoffice-qt
  ];
}