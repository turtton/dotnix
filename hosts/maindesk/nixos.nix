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
    ./../../os/core/amdgpu.nix
    ./../../os/core/shell.nix
    # Niri is configured via module/niri with packs.niri.enable
    # ./../../os/wm/hyprland.nix
    ./../../os/desktop/shared
    ./../../os/desktop/1password.nix
    ./../../os/desktop/flatpak.nix
    ./../../os/desktop/media.nix
    ./../../os/desktop/openrazer.nix
    ./../../os/desktop/steam.nix
    ./../../os/desktop/vr.nix
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-pc-ssd
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
    kernelModules = [
      "pci_stub"
      "vfio"
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
      "kvm"
      "kvm-amd"
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 64 * 1024;
    }
  ];

  services = {
    # Enable CUPS to print documents.
    printing.enable = true;
    xserver = {
      wacom.enable = true;
    };
  };

  hardware.bluetooth.enable = true;

  networking.wireguard.enable = true;
}
