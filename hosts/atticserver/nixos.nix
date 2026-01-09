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
    ./atticd.nix
    # ./cloudflared.nix
    ./../../os/core/server
    ./../../os/core/shell.nix
  ];
  # ++ (with inputs.nixos-hardware.nixosModules; [
  # common-cpu-amd
  # common-pc-ssd
  # ]);

  users.mutableUsers = true;

  boot = {
    isContainer = true;
    loader = {
      grub.enable = false;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
  };
}
