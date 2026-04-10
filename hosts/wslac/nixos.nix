{
  inputs,
  pkgs,
  hostname,
  config,
  pkgs-staging-next,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    ./../../os/core/common
    ./../../os/core/shell.nix
  ];
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  services.tailscale.enable = pkgs.lib.mkForce false;
}
