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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${username}" = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
}
