{
  hostname,
  pkgs,
  config,
  ...
}:
{
  networking = {
    hostName = hostname;
    networkmanager = {
      enable = true;
      enableStrongSwan = true;
      plugins = with pkgs; [
        networkmanager-fortisslvpn
        networkmanager-l2tp
      ];
    };
    firewall = {
      enable = true;
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # nixpkgs issue#180175
  systemd.services.NetworkManager-wait-online.enable = false;

  services.strongswan.enable = true;
  # https://github.com/NixOS/nixpkgs/issues/375352
  environment.etc."strongswan.conf".text = "";
}
