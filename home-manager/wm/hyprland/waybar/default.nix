{ pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    settings = import ./config.nix { inherit pkgs; };
    style = import ./style.nix;
    systemd.enable = true;
  };
  services.swaync = {
    enable = true;
  };
  home.packages = with pkgs; [
    waybar-mpris
  ];
}
