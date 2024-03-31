{ inputs
, pkgs
, username
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
    ./../../os/wm/plasma5.nix
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
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  system.stateVersion = "23.11";

  services = {
    # Enable CUPS to print documents.
    printing.enable = true;
    xserver.videoDrivers = [ "nvidia" ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${username}" = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  # Original: https://github.com/DarkKirb/nixos-config/pull/381
  # Add --impure option until this removed
  system.replaceRuntimeDependencies = [
    {
      original = pkgs.xz;
      replacement = pkgs-staging-next.xz;
    }
  ];
}
