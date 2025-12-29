{
  pkgs,
  lib,
  config,
  isHomeManager,
  ...
}:
let
  cfg = config.packs.rofi;
in
{
  options.packs.rofi.enable = lib.mkEnableOption "Enable rofi launcher";

  config = lib.mkIf cfg.enable (
    if isHomeManager then
      {
        programs.rofi = {
          enable = true;
          package = pkgs.rofi;
          theme = ./rofi.rasi;
        };
      }
    else
      { }
  );
}
