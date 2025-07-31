{
  inputs,
  pkgs,
  hostname,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./../../os/core/shared
    ./../../os/core/shell.nix
    # ./../../os/wm/plasma5.nix
    ./../../os/wm/hyprland.nix
    ./../../os/desktop/shared
    # (import ./../../os/desktop/nautilus.nix "alacritty")
    # ./../../os/desktop/1password.nix
    # ./../../os/desktop/flatpak.nix
    # ./../../os/desktop/media.nix
    # ./../../os/desktop/openrazer.nix
    # ./../../os/desktop/steam.nix
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    # common-gpu-nvidia
    common-pc-ssd
  ]);

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/vda";
        useOSProber = true;
      };
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    # Enable CUPS to print documents.
    printing.enable = true;
  };
}
