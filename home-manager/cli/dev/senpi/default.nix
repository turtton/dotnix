{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentDir = ".senpi/agent";

  settingsJson = pkgs.writeText "senpi-settings.json" (
    builtins.toJSON {
      permissionPreset = "workspace";
      packages = [
        "${pkgs.omo-senpi}${pkgs.omo-senpi.pluginPath}"
      ];
    }
  );
in
{
  # omo-cli は omo-senpi の ulw-loop/comment-checker コンポーネントが
  # PATH から omo / comment-checker を発見するために必要。
  home.packages = [
    pkgs.senpi
    pkgs.omo-cli
  ];

  home.activation.senpi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    senpi_dir="$HOME/${agentDir}"
    $DRY_RUN_CMD mkdir -p "$senpi_dir"
    [ -f "$senpi_dir/settings.json" ] && $DRY_RUN_CMD mv -f "$senpi_dir/settings.json" "$senpi_dir/settings.json.old"
    $DRY_RUN_CMD cp -f "${settingsJson}" "$senpi_dir/settings.json"
    $DRY_RUN_CMD chmod u+w "$senpi_dir/settings.json"
  '';
}
