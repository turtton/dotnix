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

  cfg = config.packs.remote-desktop;
in
{
  options.packs.remote-desktop = {
    enable = mkEnableOption "Remote desktop and window sharing tools";
    server = mkEnableOption "Enable remote desktop server functionality";
  };

  config = mkIf cfg.enable (
    if isHomeManager then
      {
        home.packages =
          with pkgs;
          optionals hostPlatform.isLinux [
            # window sharings
            remmina

            # parsec is not supported to host on linux, only the client
            # parsec-bin
          ];
        services.wayvnc = {
          enable = hostPlatform.isLinux && cfg.server;
          settings = {
            address = "0.0.0.0";
            port = 5900;
          };
        };
      }
    else
      {
      }
  );
}
