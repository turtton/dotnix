{
  pkgs,
  lib,
  config,
  isHomeManager,
  hostPlatform,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption optionals;

  cfg = config.packs.android;
in
{
  options.packs.android.enable = mkEnableOption "Android development environment";

  config = mkIf cfg.enable (
    if isHomeManager then
      {
        home.packages =
          with pkgs;
          optionals hostPlatform.isLinux [
            android-studio
          ];
      }
    else
      {
        # Enable android rule
        programs.adb.enable = true;
      }
  );
}
