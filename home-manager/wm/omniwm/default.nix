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
  # read-only な symlink にはできない。activation で宣言分だけを既存ファイルへマージする。
  mergeSettings = pkgs.python3.withPackages (ps: [ ps.tomli-w ]);

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

  # マージ後のファイルでエージェントが起動するよう setupLaunchAgents より前に走らせる。
  home.activation.omniwmSettings =
    lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
      ''
        run ${mergeSettings}/bin/python3 ${./merge-settings.py} \
          ${settingsFile} "${config.xdg.configHome}/omniwm/settings.toml"
      '';
}
