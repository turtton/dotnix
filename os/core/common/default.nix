{ pkgs, ... }:
{
  imports = [
    ./containerized.nix
    ./gpg.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./ssh.nix
  ];

  services.journald.extraConfig = ''
    SystemMaxFileSize=300M
  '';
}
