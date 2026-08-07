{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.packs.niri;
  theme = {
    name = "catppuccin-mocha-blue-standard";
    package = pkgs.catppuccin-gtk.override {
      variant = "mocha";
      accents = [ "blue" ];
    };
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
