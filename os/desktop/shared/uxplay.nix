{ pkgs, ... }: {
  # Original: https://github.com/n3oney/nixus/blob/192196e9c454e09c3ffbd2120778ed788f3b7c91/modules/services/uxplay.nix
  environment.systemPackages = with pkgs; [ uxplay ];
  networking.firewall = {
    allowedTCPPorts = [ 7100 7000 7001 ];
    allowedUDPPorts = [ 7011 6001 6000 ];
  };
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  systemd.user.services.uxplay = {
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Restart = "on-failure";
      Description = "AirPlay Unix mirroring server";
    };
    script = "${pkgs.uxplay}/bin/uxplay -p";
    wantedBy = [ "graphical-session.target" ];
  };
}
