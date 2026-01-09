{ pkgs, ... }:
{
  imports = [
    ../common
    ./ld.nix
    ./network.nix
    ./virtualisation.nix
  ];

  # Fix timelag for windows
  time.hardwareClockInLocalTime = true;

  # Enable usb access
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Limit the number of boot loader configurations
  boot.loader = {
    systemd-boot.configurationLimit = 5;
    grub.configurationLimit = 5;
    generic-extlinux-compatible.configurationLimit = 5;
  };
}
