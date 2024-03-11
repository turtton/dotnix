{
  inputs,
  pkgs,
  username,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
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

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    firewall = {
      enable = true;
    # trustedInterfaces = ["tailscale0"];
    # allowedUDPPorts = [config.services.tailscale.port];
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = [pkgs.fcitx5-skk];
    };
  };

  fonts = {
    fonts = with pkgs; [
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      noto-fonts-emoji
      nerdfonts
      migu
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Serif CJK JP" "Noto Color Emoji"];
        sansSerif = ["Noto Sans CJK JP" "Noto Color Emoji"];
        monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
        emoji = ["Noto Color Emoji"];
      };
      localConf = ''
       <?xml version="1.0"?>
       <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
       <fontconfig>
         <description>Change default fonts for Steam client</description>
         <match>
           <test name="prgname">
             <string>steamwebhelper</string>
           </test>
           <test name="family" qual="any">
             <string>sans-serif</string>
           </test>
           <edit mode="prepend" name="family">
             <string>Migu 1P</string>
           </edit>
         </match>
       </fontconfig>
      '';
    };
  };

  services = {
    # Enable the X11 windowing system.
    xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Enable the KDE Plasma Desktop Environment.
      displayManager.sddm = {
        enable = true;
        # wayland.enable = true;
      };
      desktopManager.plasma5.enable = true;
      # desktopManager.plasma6.enable = true;

      # Configure keymap in X11
      layout = "us";
      xkbVariant = "";
    };
    # Enable CUPS to print documents.
    printing.enable = true;
    flatpak.enable = true;
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${username}" = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      firefox
      kate
      delta
    #  thunderbird
    ];
  };

  programs = {
    git = {
      enable = true;
    };
    zsh = {
      enable = true;
    };
    noisetorch.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  xdg.portal.enable = true; # required for flatpack

  virtualisation = {
   docker = {
     enable = true;
     rootless = {
       enable = true;
       setSocketVariable = true;
     };
   };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}