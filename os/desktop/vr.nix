{ pkgs, ... }:
{
  programs = {
    alvr = {
      enable = true;
      openFirewall = true;
    };
  };
  services = {
    wivrn = {
      enable = true;
      openFirewall = true;
    };
  };
  environment.systemPackages = with pkgs; [
    bs-manager
    wayvr
  ];
}
