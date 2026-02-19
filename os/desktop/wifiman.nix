{ pkgs, ... }:
{
  systemd.services.wifiman-desktop = {
    description = "WiFiman Desktop Daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wifiman-desktop}/bin/wifiman-desktopd";
      Restart = "always";
      RestartSec = 30;
    };
  };

  environment.systemPackages = [ pkgs.wifiman-desktop ];
}
