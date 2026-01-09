{
  hostname,
  config,
  ...
}:
{
  networking = {
    hostName = hostname;
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
}
