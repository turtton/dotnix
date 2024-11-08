{ pkgs, ... }: {
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    jetbrains-dolphin
  ];
  xdg.dataFile."dolphin" = {
    source = ./share;
    recursive = true;
  };
}
