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
in
{
  launcher-contract = pkgs.runCommand "herdr-launcher-contract" { nativeBuildInputs = testInputs; } ''
    export FAKE_HERDR=${./fake-herdr.sh}
    bash ${./launcher-contract.sh} ${../../overlay/opencode/sandbox.sh}
    touch $out
  '';

  quota-contract = pkgs.runCommand "herdr-quota-contract" { nativeBuildInputs = testInputs; } ''
    export FAKE_HERDR=${./fake-herdr.sh}
    bash ${./quota-contract.sh} ${../../overlay/opencode/kimi-quota-poll.sh}
    touch $out
  '';
}
