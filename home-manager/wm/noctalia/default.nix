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
      settingsVersion = 16;
      setupCompleted = true;
      bar = {
        density = "compact";
        position = "left";
        showCapsule = false;
        floating = false;
        marginVertical = 0.20;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
            {
              id = "ActiveWindow";
              showIcon = true;
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
              id = "Tray";
            }
            {
              id = "SystemMonitor";
              compactMode = false;
              showCpuTemp = true;
              showDiskUsage = true;
              showDiskAsPercent = true;
              showCpuUsage = true;
              showGpuUsage = true;
              showMemoryUsage = true;
              showMemoryAsPercent = false;
              showNetworkStats = false;
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
      dock = {
        enabled = false;
        displayMode = "auto_hide";
        backgroundOpacity = 0.8;
        floatingRatio = 1;
        size = 1;
        onlySameOutput = true;
        monitors = [ ];
        pinnedApps = [ ];
        colorizeIcons = false;
      };
      wallpaper = {
        directory = "${pkgs.wallpaper-springcity}";
      };
      colorSchemes.predefinedScheme = "Catppuccin";
      appLauncher = {
        enableClipboardHistory = true;
      };
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
