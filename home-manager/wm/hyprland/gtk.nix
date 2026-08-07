{ pkgs, ... }:
let
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
  theme = {
    name = "catppuccin-mocha-blue-standard";
    package = pkgs.catppuccin-gtk.override {
      variant = "mocha";
      accents = [ "blue" ];
    };
  };
in
{
  gtk = {
    inherit iconTheme theme;
    enable = true;
    gtk4 = {
      inherit iconTheme theme;
    };
  };
}
