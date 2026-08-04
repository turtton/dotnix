{
  config,
  lib,
  pkgs,
  ...
}:
let
  settings = import ./settings.nix;
  settingsFile = (pkgs.formats.toml { }).generate "omniwm-settings.toml" settings;

  # OmniWM は settings.toml に [state] やワークスペース/モニタの UUID を書き戻すため、
  # read-only な symlink にすると保存に失敗する。false で完全固定にできるが GUI は使えなくなる。
  mutableSettings = true;

  appBundle = "${pkgs.omniwm}/Applications/OmniWM.app";
in
{
  home.packages = [ pkgs.omniwm ];

  launchd.agents.omniwm = {
    enable = true;
    config = {
      ProgramArguments = [ "${appBundle}/Contents/MacOS/OmniWM" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/omniwm.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/omniwm.err.log";
    };
  };

  xdg.configFile = lib.mkIf (!mutableSettings) {
    "omniwm/settings.toml".source = settingsFile;
  };

  home.activation = lib.mkIf mutableSettings {
    omniwmSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="${config.xdg.configHome}/omniwm/settings.toml"
      if [ ! -e "$target" ]; then
        run mkdir -p "$(dirname "$target")"
        run install -m 0644 ${settingsFile} "$target"
        run echo "omniwm: seeded $target"
      fi
    '';
  };
}
