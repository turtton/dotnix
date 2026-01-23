{
  pkgs,
  lib,
  config,
  inputs,
  system,
  isHomeManager,
  hostPlatform,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption optionals;

  cfg = config.packs.niri;
in
{
  imports =
    optionals isHomeManager [
      inputs.niri-flake.homeModules.niri
      ../../home-manager/wm/noctalia
      ./settings.nix
      ./key-bindings.nix
      ./window-rules.nix
      ./idle.nix
      ./noctalia.nix
      ./gtk.nix
      ./qt
      ./utilapp.nix
    ]
    ++ optionals (!isHomeManager) [
      # Don't use nixosModules.niri as it conflicts with homeModules when
      # using home-manager as NixOS module. Configure NixOS settings directly.
      inputs.noctalia.nixosModules.default
    ];

  options.packs.niri = {
    enable = mkEnableOption "Enable Niri compositor";
  };

  config = mkIf cfg.enable (
    if isHomeManager then
      {
        programs.niri.enable = true;

        home.packages =
          with pkgs;
          optionals hostPlatform.isLinux [
            brightnessctl
            grim
            slurp
            swappy
            zenity
            pamixer
            playerctl
            wl-clipboard
            cliphist
            polkit
            kdePackages.polkit-kde-agent-1
            libsecret
            networkmanagerapplet
            btop
            gcolor3
            hyprpicker
            google-cursor
            xdg-desktop-portal-gnome
            # Required by xdg-desktop-portal-gnome for FileChooser (e.g., Chromium's "Save as PDF")
            nautilus
          ];

        xdg.userDirs.createDirectories = true;
        services = {
          gnome-keyring.enable = true;
          kdeconnect.indicator = true;
        };
      }
    else
      {
        security.pam.services =
          let
            enableKeyrings = {
              enableGnomeKeyring = true;
              kwallet.enable = true;
            };
          in
          {
            login = enableKeyrings;
          };

        services = {
          upower.enable = true;
          power-profiles-daemon.enable = true;
          noctalia-shell.enable = true;
        };

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
          configPackages = [ inputs.niri-flake.packages.${system}.niri-stable ];
        };

        programs.dconf.enable = true;

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          XDG_CURRENT_DESKTOP = "niri";
        };
      }
  );
}
