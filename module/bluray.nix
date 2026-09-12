{
  pkgs,
  lib,
  config,
  isHomeManager,
  hostPlatform,
  usernames ? [ ],
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    optionals
    genAttrs
    ;

  cfg = config.packs.bluray;

  backends = {
    makemkv = {
      LIBAACS_PATH = "${pkgs.makemkv}/lib/libmmbd";
      LIBBDPLUS_PATH = "${pkgs.makemkv}/lib/libmmbd";
      MAKEMKVCON = "${pkgs.makemkv}/bin/makemkvcon";
    };
    libaacs = {
      LIBAACS_PATH = "${pkgs.libaacs}/lib/libaacs";
      LIBBDPLUS_PATH = "${pkgs.libbdplus}/lib/libbdplus";
    };
  };
in
{
  options.packs.bluray = {
    enable = mkEnableOption "Play AACS/BD+ protected Blu-ray discs";
    backend = mkOption {
      type = types.enum (builtins.attrNames backends);
      default = "makemkv";
      description = "Decryption library exposed to libbluray via LIBAACS_PATH/LIBBDPLUS_PATH";
    };
  };

  config = mkIf cfg.enable (
    if isHomeManager then
      {
        home.packages =
          with pkgs;
          optionals hostPlatform.isLinux ([ libbluray ] ++ optionals (cfg.backend == "makemkv") [ makemkv ]);
      }
    else
      {
        boot.kernelModules = [ "sg" ];
        users.users = genAttrs usernames (_: {
          extraGroups = [ "cdrom" ];
        });
        # vlc links libbluray-full, which hardcodes nixpkgs libaacs/libbdplus and ignores these; only mpv honors them
        environment.sessionVariables = backends.${cfg.backend};
      }
  );
}
