{ pkgs, ... }:
{
  home.packages = with pkgs; [
    krita
    gimp
  ];
}
