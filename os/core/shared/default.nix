{ pkgs, ... }:
{
  imports = [
    ./gpg.nix
    ./ld.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./ssh.nix
    ./virtualisation.nix
  ];
  # Fix timelag for windows
  time.hardwareClockInLocalTime = true;

  services.journald.extraConfig = ''
    SystemMaxFileSize=300M
  '';

  # Enable usb access
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Enable android rule
  programs.adb.enable = true;

  # Limit the number of boot loader configurations
  boot.loader = {
    systemd-boot.configurationLimit = 5;
    grub.configurationLimit = 5;
    generic-extlinux-compatible.configurationLimit = 5;
  };
}
