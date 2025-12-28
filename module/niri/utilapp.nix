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
      kdePackages.gwenview # Image viewer
    ];
  };
}
