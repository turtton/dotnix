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
      permissionPreset = "full-access";
      packages = [
        "${pkgs.omo-senpi}${pkgs.omo-senpi.pluginPath}"
      ];
    }
  );

  # Registered provider/catalog for the local CLIProxyAPI; see ./models-json.nix.
  proxyModels = import ../cli-proxy-models.nix;
  modelsJson = pkgs.writeText "senpi-models.json" (
    builtins.toJSON (import ./models-json.nix { inherit proxyModels; })
  );
in
{
  home.packages = [
    pkgs.senpi
    pkgs.omo-cli
    pkgs.ripgrep
  ];

  home.activation.senpi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    senpi_dir="$HOME/${agentDir}"
    $DRY_RUN_CMD mkdir -p "$senpi_dir"
    [ -f "$senpi_dir/settings.json" ] && $DRY_RUN_CMD mv -f "$senpi_dir/settings.json" "$senpi_dir/settings.json.old"
    $DRY_RUN_CMD cp -f "${settingsJson}" "$senpi_dir/settings.json"
    $DRY_RUN_CMD chmod u+w "$senpi_dir/settings.json"

    [ -f "$senpi_dir/models.json" ] && $DRY_RUN_CMD mv -f "$senpi_dir/models.json" "$senpi_dir/models.json.old"
    $DRY_RUN_CMD cp -f "${modelsJson}" "$senpi_dir/models.json"
    $DRY_RUN_CMD chmod u+w "$senpi_dir/models.json"

    [ -f "$senpi_dir/sandbox.json" ] && $DRY_RUN_CMD mv -f "$senpi_dir/sandbox.json" "$senpi_dir/sandbox.json.old"
  '';
}
