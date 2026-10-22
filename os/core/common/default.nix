{ pkgs, ... }:
{
  imports = [
    ./claude-code.nix
    ./containerized.nix
    ./gpg.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./ssh.nix
  ];

  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];

  services.journald.settings.Journal = {
    SystemMaxFileSize = "300M";
  };
}
