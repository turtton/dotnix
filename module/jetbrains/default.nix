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

  cfg = config.packs.jetbrains;
  anyEnabled = cfg.toolbox.enable || lib.any (ide: ide.enable) (lib.attrValues cfg.ides);
in
{
  options.packs.jetbrains = {
    toolbox.enable = mkEnableOption "JetBrains Toolbox (Linux only)";
    ides = {
      idea.enable = mkEnableOption "IntelliJ IDEA";
      webstorm.enable = mkEnableOption "WebStorm";
      rust-rover.enable = mkEnableOption "RustRover";
      datagrip.enable = mkEnableOption "DataGrip";
      pycharm.enable = mkEnableOption "PyCharm";
      clion.enable = mkEnableOption "CLion";
      rider.enable = mkEnableOption "Rider";
    };
  };

  config = mkIf anyEnabled (
    if isHomeManager then
      {
        # jetbrains.plugins.addPlugins fails to build; plugin ids are listed in
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/jetbrains/plugins/plugins.json
        home.packages =
          with pkgs.jetbrains;
          optionals cfg.ides.idea.enable [ idea ]
          ++ optionals cfg.ides.webstorm.enable [ webstorm ]
          ++ optionals cfg.ides.rust-rover.enable [ rust-rover ]
          ++ optionals cfg.ides.datagrip.enable [ datagrip ]
          ++ optionals cfg.ides.pycharm.enable [ pycharm ]
          ++ optionals cfg.ides.clion.enable [ clion ]
          ++ optionals cfg.ides.rider.enable [ rider ]
          # basically should not use toolbox because of issues(https://github.com/NixOS/nixpkgs/issues/240444) but useful to preview IDE
          ++ optionals (cfg.toolbox.enable && hostPlatform.isLinux) [ pkgs.jetbrains-toolbox ];

        home.file.".ideavimrc".source = ./ideavimrc;
      }
    else
      { }
  );
}
