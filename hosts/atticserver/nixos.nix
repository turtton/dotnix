{ inputs
, pkgs
, hostname
, config
, pkgs-staging-next
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./atticd.nix
    ./../../os/core/shared
    ./../../os/core/shell.nix
  ];
  # ++ (with inputs.nixos-hardware.nixosModules; [
  # common-cpu-amd
  # common-pc-ssd
  # ]);

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
  };

  system.stateVersion = "24.04";
}
