{
  inputs,
  hostname,
  lib,
  ...
}:
let
  # adguard-cli generates a per-machine CA certificate on `adguard-cli configure`.
  # To trust it system-wide, copy the public cert into this repo and rebuild:
  #   cp ~/.local/share/adguard-cli/"AdGuard CLI CA.pem" hosts/$(hostname)/adguard-ca.pem
  #   git add hosts/$(hostname)/adguard-ca.pem
  # (flakes cannot reference runtime paths outside the repo, so the cert is
  #  picked up here only when it exists in the tree)
  caCert = ../../../hosts + "/${hostname}/adguard-ca.pem";
in
{
  imports = [ inputs.adguard-cli-flake.nixosModules.default ];

  programs.adguard-cli.enable = true;

  security.pki.certificateFiles = lib.optional (builtins.pathExists caCert) caCert;
}
