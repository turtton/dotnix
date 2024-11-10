{ pkgs, ... }: {
  home.packages = with pkgs; [
    # eog # Image viewer
    libsForQt5.gwenview # Image viewer
  ];
}
