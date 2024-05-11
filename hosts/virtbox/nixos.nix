{ inputs
, pkgs
, username
, hostname
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./../../os/core/shared
    ./../../os/core/shell.nix
    # ./../../os/wm/plasma5.nix
    ./../../os/wm/hyprland.nix
    ./../../os/desktop/shared
    # ./../../os/desktop/1password.nix
    # ./../../os/desktop/flatpak.nix
    # ./../../os/desktop/media.nix
    # ./../../os/desktop/openrazer.nix
    # ./../../os/desktop/steam.nix
  ] ++ (with inputs.nixos-hardware.nixosModules; [
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
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
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
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland
        '';
        user = username;
      };
    };
  };
}
