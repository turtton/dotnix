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
        "npm:pi-sandbox@0.6.2"
      ];
    }
  );

  sandboxJson = pkgs.writeText "pi-sandbox.json" (
    builtins.toJSON {
      enabled = true;
      network.allowedDomains = [
        "npmjs.org"
        "*.npmjs.org"
        "registry.npmjs.org"
        "registry.yarnpkg.com"
        "files.pythonhosted.org"
        "pypi.org"
        "*.pypi.org"
        "github.com"
        "*.github.com"
        "api.github.com"
        "raw.githubusercontent.com"
        "objects.githubusercontent.com"
        "crates.io"
        "*.crates.io"
        "static.crates.io"
        "proxy.golang.org"
        "sum.golang.org"
        "cache.nixos.org"
        "rubygems.org"
        "*.rubygems.org"
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
    pkgs.ripgrep
    pkgs.bubblewrap
    pkgs.socat
  ];

  home.activation.senpi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    senpi_dir="$HOME/${agentDir}"
    $DRY_RUN_CMD mkdir -p "$senpi_dir"
    [ -f "$senpi_dir/settings.json" ] && $DRY_RUN_CMD mv -f "$senpi_dir/settings.json" "$senpi_dir/settings.json.old"
    $DRY_RUN_CMD cp -f "${settingsJson}" "$senpi_dir/settings.json"
    $DRY_RUN_CMD chmod u+w "$senpi_dir/settings.json"

    [ -f "$senpi_dir/sandbox.json" ] && $DRY_RUN_CMD mv -f "$senpi_dir/sandbox.json" "$senpi_dir/sandbox.json.old"
    $DRY_RUN_CMD cp -f "${sandboxJson}" "$senpi_dir/sandbox.json"
    $DRY_RUN_CMD chmod u+w "$senpi_dir/sandbox.json"
  '';
}
