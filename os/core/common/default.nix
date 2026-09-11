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

  services.journald.settings.Journal = {
    SystemMaxFileSize = "300M";
  };
}
