{
  pkgs,
  lib,
  config,
  isHomeManager,
  hostPlatform,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkMerge
    optionals
    ;
  cfg = config.packs.bitwarden;
in
{
  options.packs.bitwarden = {
    enable = mkEnableOption "Bitwarden password manager";
    ssh-agent = mkEnableOption "Bitwarden SSH agent integration";
  };

  config = mkIf cfg.enable (
    if isHomeManager then
      mkMerge [
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
              bitwarden-desktop
            ];
        }
        (mkIf (cfg.ssh-agent && hostPlatform.isLinux) {
          home.sessionVariables = {
            SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
          };
          services.gnome-keyring.components = [
            "secrets"
            "pkcs11"
          ];
        })
      ]
    else
      { }
  );
}
