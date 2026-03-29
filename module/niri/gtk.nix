{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.packs.niri;
  theme = {
    name = "Tokyonight-Dark";
    package = pkgs.tokyonight-gtk-theme;
  };
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
in
{
  config = lib.mkIf cfg.enable {
    gtk = {
      inherit theme iconTheme;
      enable = true;
      gtk4 = {
        inherit theme iconTheme;
      };
    };
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
