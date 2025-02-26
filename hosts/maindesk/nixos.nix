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
    ./../../os/desktop/openrazer.nix
    ./../../os/desktop/steam.nix
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-pc-ssd
  ]);

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
    kernelModules = [ "pci_stub" "vfio" "vfio" "vfio_iommu_type1" "vfio_pci" "kvm" "kvm-amd" ];
    kernelParams = [
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    nvidia-container-toolkit = {
      enable = true;
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
      videoDrivers = [ "nvidia" ];
      wacom.enable = true;
    };
  };

  hardware.bluetooth.enable = true;

  environment.defaultPackages = [
    pkgs.nvidia-docker
  ];
}
