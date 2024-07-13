{ inputs
, pkgs
, hostname
, config
, pkgs-staging-next
, ...
}: {
  imports = [
    ./../../os/core/shared
    ./../../os/core/shell.nix
  ];
  # ++ (with inputs.nixos-hardware.nixosModules; [
  # common-cpu-amd
  # common-pc-ssd
  # ]);

  boot = {
    isContainer = true;
    loader = {
      grub.enable = false;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
  };

  system.stateVersion = "24.04";
}
