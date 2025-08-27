{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # eog # Image viewer
    kdePackages.gwenview # Image viewer
  ];
}
