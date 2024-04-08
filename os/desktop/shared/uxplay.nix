{ pkgs, hostname, ... }: {
  # Original: https://github.com/n3oney/nixus/blob/192196e9c454e09c3ffbd2120778ed788f3b7c91/modules/services/uxplay.nix
  environment.systemPackages = with pkgs; [ uxplay ];
  networking.firewall = {
    allowedTCPPorts = [ 7100 7000 7001 ];
    allowedUDPPorts = [ 7011 6001 6000 ];
  };
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  systemd.user.services.uxplay = {
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
    };
    script = "${pkgs.uxplay}/bin/uxplay -n \"${hostname}\" -nh -p";
  };
}
