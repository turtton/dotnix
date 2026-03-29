{ pkgs, ... }:
let
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
  theme = {
    name = "Tokyonight-Dark";
    package = pkgs.tokyonight-gtk-theme;
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
