{ pkgs, ... }:
{
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-fortisslvpn
      networkmanager-l2tp
      networkmanager_strongswan
    ];
  };
  networking.firewall = {
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
  };

  # nixpkgs issue#180175
  systemd.services.NetworkManager-wait-online.enable = false;

  services.strongswan.enable = true;
  # https://github.com/NixOS/nixpkgs/issues/375352
  environment.etc."strongswan.conf".text = "";
}
