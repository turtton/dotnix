# Herdr migration contract checks — RED until the launcher (Wave 4) and quota
# pollers (Wave 3) are converted. Not wired into flake.nix; evaluate standalone:
#
#   cd "$(git rev-parse --show-toplevel)"
#   rev=$(jq -r .nodes.nixpkgs.locked.rev flake.lock)
#   nix build -f tests/herdr/default.nix launcher-contract \
#     --arg pkgs "import (builtins.fetchTarball \"https://github.com/NixOS/nixpkgs/archive/$rev.tar.gz\") {}"
#
# (`--arg pkgs 'import <nixpkgs> {}'` also works; the pinned tarball matches CI.)
{ pkgs }:

let
  testInputs = with pkgs; [
    bash
    coreutils
    curl
    gnugrep
    gnused
    jq
    procps
    python3
    util-linux
  ];

  # 実際に配備される生成物。senpi-launcher-contract は SENPI_HERDR_CHILD_WRAPPER で
  # スタブに差し替えるため本物を検査できず、実行ビット欠落 (writeText 化) を見逃した。
  senpiHerdrChild = import ../../overlay/senpi/herdr-child.nix {
    inherit (pkgs) writeText writeShellScript;
  };

  # overlay/opencode/default.nix の mkQuotaPoller と同じ規約で __QUOTA_REPORT__ を置換する。
  # ビルドサンドボックスには /usr/bin/env が無いので、quota-report の shebang は
  # bash のストアパスに張り替えないとポーラーからの直接 exec が失敗する
  quotaReport = pkgs.runCommand "quota-report.sh" { } ''
    sed "1s|^#!.*|#!${pkgs.bash}/bin/bash|" ${../../overlay/opencode/quota-report.sh} > $out
    chmod +x $out
  '';

  kimiQuotaPoller = pkgs.writeText "kimi-quota-poll.sh" (
    builtins.replaceStrings [ "__QUOTA_REPORT__" ] [ "${quotaReport}" ] (
      builtins.readFile ../../overlay/opencode/kimi-quota-poll.sh
    )
  );
in
{
  launcher-contract = pkgs.runCommand "herdr-launcher-contract" { nativeBuildInputs = testInputs; } ''
    export FAKE_HERDR=${./fake-herdr.sh}
    bash ${./launcher-contract.sh} ${../../overlay/opencode/sandbox.sh}
    touch $out
  '';

  child-wrapper-contract =
    pkgs.runCommand "herdr-child-wrapper-contract" { nativeBuildInputs = testInputs; }
      ''
        bash ${./child-wrapper-contract.sh} ${../../overlay/opencode/child-wrapper.sh}
        touch $out
      '';

  senpi-launcher-contract =
    pkgs.runCommand "senpi-herdr-launcher-contract" { nativeBuildInputs = testInputs; }
      ''
        export FAKE_HERDR=${./fake-herdr.sh}
        bash ${./senpi-launcher-contract.sh} ${../../overlay/senpi/senpi-herdr.sh}
        touch $out
      '';

  # senpi-herdr.sh は child wrapper を env 経由で直接 exec するため、
  # 生成物に実行ビットが無いと herdr ペイン内で Permission denied になる。
  senpi-child-wrapper-executable = pkgs.runCommand "senpi-child-wrapper-executable" { } ''
    if [ ! -x ${senpiHerdrChild} ]; then
      echo "senpi-herdr-child-wrapper.sh is not executable: ${senpiHerdrChild}" >&2
      exit 1
    fi
    touch $out
  '';

  # RED: overlay/senpi/sandbox.sh は未作成のため path 不在の eval エラーで失敗する
  senpi-sandbox-contract =
    pkgs.runCommand "senpi-sandbox-contract" { nativeBuildInputs = testInputs; }
      ''
        bash ${./senpi-sandbox-contract.sh} ${../../overlay/senpi/sandbox.sh}
        touch $out
      '';

  # RED: child-wrapper 呼出規約 (project_dir, senpi_bin, args...) を senpi-sandbox
  # 呼び出しへ変換する shim。overlay/senpi/senpi-sandbox-shim.sh として作成される予定。
  senpi-sandbox-shim-executable =
    let
      shim = ../../overlay/senpi/senpi-sandbox-shim.sh;
    in
    pkgs.runCommand "senpi-sandbox-shim-executable" { } (
      if builtins.pathExists shim then
        ''
          if [ ! -x ${shim} ]; then
            echo "senpi-sandbox-shim.sh is not executable: ${shim}" >&2
            exit 1
          fi
          touch $out
        ''
      else
        ''
          echo "senpi-sandbox-shim.sh does not exist yet (expected: overlay/senpi/senpi-sandbox-shim.sh)" >&2
          exit 1
        ''
    );

  quota-contract = pkgs.runCommand "herdr-quota-contract" { nativeBuildInputs = testInputs; } ''
    export FAKE_HERDR=${./fake-herdr.sh}
    bash ${./quota-contract.sh} ${kimiQuotaPoller}
    touch $out
  '';
}
