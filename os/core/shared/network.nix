{ hostname
, pkgs
, config
, ...
}: {
  networking = {
    hostName = hostname;
    networkmanager = {
      enable = true;
      plugins = with pkgs; [ networkmanager-fortisslvpn ];
    };
    firewall = {
      enable = true;
      allowedTCPPortRanges = [
        { from = 1714; to = 1764; } # KDE Connect
      ];
      allowedUDPPortRanges = [
        { from = 1714; to = 1764; } # KDE Connect
      ];
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
  services.tailscale = {
    enable = true;
    openFirewall = true;
    interfaceName = "userspace-networking";
  };

  # nixpkgs issue#180175
  systemd.services.NetworkManager-wait-online.enable = false;
}
