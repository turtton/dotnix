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
  cfg = config.packs.bitwarden;
in
{
  options.packs.bitwarden = {
    enable = mkEnableOption "Bitwarden password manager";
  };

  config = mkIf cfg.enable (
    if isHomeManager then
      {
        programs.rbw = {
          enable = true;
          settings = {
            email = "fun.dust0146@turtton.net";
            pinentry = if hostPlatform.isLinux then pkgs.pinentry-qt else pkgs.pinentry_mac;
          };
        };
        home.packages =
          with pkgs;
          optionals hostPlatform.isLinux [
            bitwarden-cli
          ];
      }
    else
      {
        environment.systemPackages = [
          pkgs.bitwarden-desktop
        ];
      }
  );
}
