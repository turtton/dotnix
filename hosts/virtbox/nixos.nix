{
  inputs,
  pkgs,
  username,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./../../os/core/shared
    ./../../os/core/shell.nix
    ./../../os/wm/plasma5.nix
    ./../../os/desktop/shared
    ./../../os/desktop/1password.nix
    ./../../os/desktop/flatpak.nix
    ./../../os/desktop/media.nix
    ./../../os/desktop/steam.nix
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-gpu-nvidia
    common-pc-ssd
  ]);

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
      };
    };
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  };

  system.stateVersion = "23.11";

  services = {
    # Enable CUPS to print documents.
    printing.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${username}" = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      firefox
      delta
    ];
  };
}