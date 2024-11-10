{ pkgs, ... }: {
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    jetbrains-dolphin-qt6
  ];
  xdg.dataFile."dolphin" = {
    source = ./share;
    recursive = true;
  };
}
