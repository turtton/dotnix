{
  imports = [
    ./gpg.nix
    ./ld.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./virtualisation.nix
  ];
  # Fix timelag for windows
  time.hardwareClockInLocalTime = true;
}