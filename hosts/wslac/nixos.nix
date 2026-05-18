{
  pkgs,
  ...
}:
{
  imports = [
    ./../../os/core/common
    ./../../os/core/shell.nix
  ];
  wsl.enable = true;
  wsl.defaultUser = "nixos";

  services.tailscale.enable = pkgs.lib.mkForce false;
}
