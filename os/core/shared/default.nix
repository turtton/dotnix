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
}
