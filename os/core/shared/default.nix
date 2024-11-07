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
}
