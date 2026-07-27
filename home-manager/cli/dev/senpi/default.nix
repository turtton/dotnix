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
        "git:github.com/code-yeongyu/pi-lsp-client"
        "git:github.com/code-yeongyu/pi-ast-grep"
        "git:github.com/code-yeongyu/pi-comment-checker"
        "git:github.com/code-yeongyu/pi-task"
        "npm:pi-sandbox"
      ];
    }
  );

  # npm 版 pi-sandbox のグローバル設定は getAgentDir() 基準、つまり senpi では
  # ~/.senpi/agent/sandbox.json (~/.pi ではない)。プロジェクト側は
  # <cwd>/.pi/sandbox.json で上書きでき、配列はグローバルと和集合マージされる。
  # スキーマは @carderne/sandbox-runtime の SandboxRuntimeConfig。
  # 注意: 配列をグローバルで定義するとデフォルト値が置き換わるため、
  # allowedDomains はデフォルト分を含めて列挙している。
  sandboxJson = pkgs.writeText "pi-sandbox.json" (
    builtins.toJSON {
      enabled = true;
      network.allowedDomains = [
        "npmjs.org"
        "*.npmjs.org"
        "registry.npmjs.org"
        "registry.yarnpkg.com"
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
  home.packages = [ pkgs.senpi ];

  home.activation.senpi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    senpi_dir="$HOME/${agentDir}"
    mkdir -p "$senpi_dir"
    [ -f "$senpi_dir/settings.json" ] && mv -f "$senpi_dir/settings.json" "$senpi_dir/settings.json.old"
    cp -f "${settingsJson}" "$senpi_dir/settings.json"
    chmod u+w "$senpi_dir/settings.json"

    [ -f "$senpi_dir/sandbox.json" ] && mv -f "$senpi_dir/sandbox.json" "$senpi_dir/sandbox.json.old"
    cp -f "${sandboxJson}" "$senpi_dir/sandbox.json"
    chmod u+w "$senpi_dir/sandbox.json"

    # settings.json の packages と実体を同期する。インストール済みかは
    # クローン/展開先ディレクトリの存在で判定し、欠けているものだけ
    # senpi install する (ネットワーク障害時は警告に留めて activation を継続)。
    SENPI="${pkgs.senpi}/bin/senpi-bare"
    install_ext() {
      local src="$1" marker="$2"
      if [ ! -e "$marker" ]; then
        "$SENPI" install "$src" \
          || echo "WARNING: senpi install $src failed. Run manually later: senpi install $src" >&2
      fi
    }
    install_ext "git:github.com/code-yeongyu/pi-lsp-client" "$senpi_dir/git/github.com/code-yeongyu/pi-lsp-client"
    install_ext "git:github.com/code-yeongyu/pi-ast-grep" "$senpi_dir/git/github.com/code-yeongyu/pi-ast-grep"
    install_ext "git:github.com/code-yeongyu/pi-comment-checker" "$senpi_dir/git/github.com/code-yeongyu/pi-comment-checker"
    install_ext "git:github.com/code-yeongyu/pi-task" "$senpi_dir/git/github.com/code-yeongyu/pi-task"
    install_ext "npm:pi-sandbox" "$senpi_dir/npm/node_modules/pi-sandbox"
  '';
}
