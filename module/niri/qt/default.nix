{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.packs.niri;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kdePackages.qt6ct
      libsForQt5.qt5ct
      kdePackages.qtwayland
      kdePackages.qtstyleplugin-kvantum
      # kdePackages.breeze-icons
    ];
    qt = {
      enable = true;
      style.name = "kvantum";
      platformTheme.name = "qtct";
    };
    xdg.configFile = {
      "qt5ct/qt5ct.conf".source = ./qt5ct.conf;
      "qt6ct/qt6ct.conf".source = ./qt6ct.conf;
      "Kvantum" = {
        source = ./kvantum;
        recursive = true;
      };
      "kdeglobals".source = ./kdeglobals;
    };
  };
}
