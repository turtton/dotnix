{ pkgs, ... }:
let
  podmanBin = pkgs.lib.getExe pkgs.podman;
  podmanMachineStart = pkgs.writeShellScript "podman-machine-start" ''
    set -eu

    if ${podmanBin} machine inspect --format '{{.State}}' 2>/dev/null | grep -q running; then
      exit 0
    fi

    exec ${podmanBin}/bin/podman machine start
  '';
in
{
  environment.systemPackages = [
    pkgs.podman
    pkgs.podman-compose
  ];
  launchd.agents.podman-machine-start = {
    enable = true;

    config = {
      Label = "local.podman-machine-start";
      ProgramArguments = [ "${podmanMachineStart}" ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/podman-machine-start.out.log";
      StandardErrorPath = "/tmp/podman-machine-start.err.log";
    };
  };
}
