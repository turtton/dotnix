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
  cfg = config.packs.noctalia;
  hyprlandEnabled = config.wayland.windowManager.hyprland.enable or false;
in
{
  imports =
    lib.optionals (isHomeManager && hostPlatform.isLinux) [
      inputs.noctalia.homeModules.default
    ]
    ++ lib.optionals (!isHomeManager && hostPlatform.isLinux) [
      inputs.noctalia.nixosModules.default
    ];

  options.packs.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell (bar, launcher, lock screen)";
  };

  config = lib.mkIf cfg.enable (
    if !hostPlatform.isLinux then
      { }
    else if isHomeManager then
      lib.mkMerge [
        {
          home.packages = with pkgs; [
            inputs.noctalia.packages.${system}.default
            wl-clipboard
            cliphist
            kdePackages.qttools
          ];
          programs.noctalia-shell = {
            enable = true;
            plugins = {
              sources = [
                {
                  enabled = true;
                  name = "Official Noctalia Plugins";
                  url = "https://github.com/noctalia-dev/noctalia-plugins";
                }
              ];
              states = {
                kde-connect = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
              };
              version = 2;
            };
            settings = {
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
                      id = "KdeConnect";
                    }
                    {
                      id = "MediaMini";
                    }
                    {
                      id = "ActiveWindow";
                      showIcon = true;
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
          };
        }
        # Hyprland-specific keybindings
        (lib.mkIf hyprlandEnabled {
          wayland.windowManager.hyprland.settings = {
            bind = [
              "$mainMod, V, exec, noctalia-shell ipc call launcher clipboard"
              "$mainMod, d, exec, noctalia-shell ipc call launcher toggle"
              "$mainMod SHIFT, d, exec, noctalia-shell ipc call launcher calculator"
            ];
          };
        })
      ]
    else
      {
        services.noctalia-shell.enable = true;
      }
  );
}
