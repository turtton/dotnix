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
    ./hardware-configuration.nix
    ./../../os/core/shared
    ./../../nixosModules/preloader-signed.nix
    ./../../os/core/shell.nix
    ./../../os/desktop/shared
    ./../../os/desktop/1password.nix
    ./../../os/desktop/flatpak.nix
    ./../../os/desktop/media.nix
    ./../../os/desktop/steam.nix
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-pc-laptop
    common-pc-laptop-ssd
  ]);

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        preloader-signed = {
          enable = true;
          efiSystemDrive = "nvme0n1";
          efiPartId = "1";
        };
      };
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
    udev.extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="16f4", ATTR{idProduct}=="4001",RUN+="/bin/sh -c 'modprobe -q ftdi-sio'",RUN+="/bin/sh -c 'echo 16f4 4001 >/sys/bus/usb-serial/drivers/ftdi_sio/new_id'"
    '';
  };

  hardware.bluetooth.enable = true;
}
