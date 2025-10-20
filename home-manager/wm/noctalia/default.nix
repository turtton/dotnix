{
  pkgs,
  inputs,
  system,
  ...
}:
{
  imports = [
    inputs.noctalia.homeModules.default
    ./hyprland.nix
  ];
  home.packages = with pkgs; [
    inputs.noctalia.packages.${system}.default
    wl-clipboard # clipboard manager
    cliphist # clipboard history
  ];
  # configure options
  programs.noctalia-shell = {
    enable = true;
    settings = {
      # configure noctalia here; defaults will
      # be deep merged with these attributes.
      bar = {
        density = "compact";
        position = "top";
        showCapsule = false;
        widgets = {
          left = [
            {
              id = "SidePanelToggle";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
            {
              id = "MediaMini";
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              id = "SystemMonitor";
            }
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 20;
            }
            {
              id = "Volume";
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
            {
              id = "NotificationHistory";
            }
          ];
        };
      };
      wallpaper = {
        defaultWallpaper = "${pkgs.wallpaper-springcity}/wall.png";
      };
      colorSchemes.predefinedScheme = "Catppuccin";
      general = {
        avatarImage = "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake.png";
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = true;
        name = "Kyoto, Japan";
      };
    };
    # this may also be a string or a path to a JSON file,
    # but in this case must include *all* settings.
  };
}
