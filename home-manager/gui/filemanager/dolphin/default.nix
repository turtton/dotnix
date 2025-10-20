{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kio-extras
    jetbrains-dolphin-qt6
    kdePackages.ark
  ];
  xdg.dataFile = {
    "dolphin" = {
      source = ./share;
      recursive = true;
    };
    "state/dolphinstaterc".source = ./dolphinstaterc;
  };
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = [ "${pkgs.dolphin}/share/applications/org.kde.dolphin.desktop" ];
  };
}
