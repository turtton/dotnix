{ pkgs, ... }: {
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    jetbrains-dolphin
  ];
}
