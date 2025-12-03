{
  pkgs,
  lib,
  config,
  isHomeManager,
  hostPlatform,
  system,
  inputs,
  usernames ? [ ],
  ...
}:
let
  inherit (lib) mkIf mkEnableOption optionals;

  cfg = config.packs.winapps;
in
{
  options.packs.winapps = {
    enable = mkEnableOption "Run Windows apps such as Microsoft Office/Adobe in Linux";
  };

  config = mkIf cfg.enable (
    if isHomeManager then
      {
        xdg.configFile."winapps/winapps.conf".source = ./winapps.conf;
        xdg.configFile."winapps/compose.yaml".source = ./compose.yaml;
      }
    else
      {
        environment.systemPackages =
          with pkgs;
          optionals hostPlatform.isLinux [
            inputs.winapps.packages."${system}".winapps
            inputs.winapps.packages."${system}".winapps-launcher
          ];
        virtualisation.podman.enable = true;
        virtualisation.podman.extraPackages = [
          pkgs.podman-compose
        ];
        users = lib.mergeAttrsList (map (name: { users."${name}".extraGroups = [ "kvm" ]; }) usernames);
      }
  );
}
