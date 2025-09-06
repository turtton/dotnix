{ pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    settings = import ./config.nix { inherit pkgs; };
    style = builtins.readFile ./style.css;
    systemd.enable = true;
  };
  services.swaync = {
    enable = true;
    style = builtins.readFile ./swaync-style.css;
  };
  home.packages = with pkgs; [
    waybar-mpris
  ];
}
