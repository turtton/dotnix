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
    gnugrep
    gnused
    jq
    util-linux
  ];

  # 実際に配備される生成物。senpi-launcher-contract は SENPI_HERDR_CHILD_WRAPPER で
  # スタブに差し替えるため本物を検査できず、実行ビット欠落 (writeText 化) を見逃した。
  senpiHerdrChild = import ../../overlay/senpi/herdr-child.nix {
    inherit (pkgs) writeText writeShellScript;
  };
in
{
  launcher-contract = pkgs.runCommand "herdr-launcher-contract" { nativeBuildInputs = testInputs; } ''
    export FAKE_HERDR=${./fake-herdr.sh}
    bash ${./launcher-contract.sh} ${../../overlay/opencode/sandbox.sh}
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

  quota-contract = pkgs.runCommand "herdr-quota-contract" { nativeBuildInputs = testInputs; } ''
    export FAKE_HERDR=${./fake-herdr.sh}
    bash ${./quota-contract.sh} ${../../overlay/opencode/kimi-quota-poll.sh}
    touch $out
  '';
}
