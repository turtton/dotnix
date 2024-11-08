{ pkgs, ... }: {
  programs.waybar = {
    enable = true;
    settings = import ./config.nix { inherit pkgs; };
    style = import ./style.nix;
  };
}
