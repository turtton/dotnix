{
  config,
  lib,
  pkgs,
  hostPlatform,
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
      filesystem = {
        # pi-sandbox は設定された allowRead/allowWrite でデフォルトを「置換」する
        # (merge ではない)ため、デフォルト分 (".", "/tmp") もここに列挙しておく。
        # 許可範囲は overlay/opencode/sandbox.sh が bind/ro-bind する領域に揃える。
        # denyRead/denyWrite は未設定でデフォルト (["/Users", "/home"] 等) を維持し、
        # ここに列挙したパスが /home 配下の carve-out として許可される。
        allowRead = [
          "."
          "~/.omo"
          "~/.senpi"
          "~/.config/opencode"
          "~/.local/share/opencode"
          "~/.local/state/opencode"
          "~/.cache/opencode"
          "~/.config/herdr"
          "~/.gitconfig"
          "~/.config/git"
          "~/.config/gh"
          "~/.docker"
          "~/.config/containers"
          "/etc"
          "/usr"
          "/bin"
          "/lib"
          "/lib64"
          "/nix"
          "/run/current-system"
          "/run/booted-system"
          "/run/nixos"
          "/run/wrappers"
          "/run/systemd/resolve"
          "/run/opengl-driver"
          "/run/opengl-driver-32"
        ];
        allowWrite = [
          "."
          "/tmp"
          "~/.omo"
          "~/.senpi"
          "~/.config/opencode"
          "~/.local/share/opencode"
          "~/.local/state/opencode"
          "~/.cache/opencode"
          "~/.claude"
          "~/.rustup"
          "~/.cargo"
          "~/.gnupg"
          "/nix/var/nix/daemon-socket"
        ];
      };
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
  home.packages = [
    pkgs.senpi
    pkgs.omo-cli
    pkgs.ripgrep
    pkgs.socat
  ]
  ++ lib.optionals hostPlatform.isLinux [
    pkgs.bubblewrap
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
