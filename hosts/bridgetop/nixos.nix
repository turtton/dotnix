{ inputs
, pkgs
, hostname
, config
, pkgs-staging-next
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./../../os/core/shared
    (import ./../../os/core/secureboot/preloader.nix "nvme0n1" "1")
    ./../../os/core/shell.nix
    ./../../os/wm/hyprland.nix
    ./../../os/desktop/shared
    ./../../os/desktop/1password.nix
    ./../../os/desktop/flatpak.nix
    ./../../os/desktop/media.nix
    ./../../os/desktop/steam.nix
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-pc-laptop
    common-pc-laptop-ssd
  ]);

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  services = {
    # Enable CUPS to print documents.
    printing.enable = true;
  };

  hardware.bluetooth.enable = true;
}
