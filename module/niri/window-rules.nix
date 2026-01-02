{ lib, config, ... }:
let
  cfg = config.packs.niri;

  opaqueApps = [
    "discord"
    "vesktop"
    "Slack"
    "zoom"
    "vivaldi"
    "chromium"
    "zen"
    "firefox"
    "jetbrains"
    "swappy"
    "Minecraft"
    "com.obsproject.Studio"
    "krita"
    "factorio"
    "code"
    "org.remmina.Remmina"
    ".*\\.exe"
  ];

  mkOpaqueRule = app: {
    matches = [
      { app-id = "^${app}.*$"; }
    ];
    opacity = 1.0;
  };

  opaqueRules = map mkOpaqueRule opaqueApps;
in
{
  config = lib.mkIf cfg.enable {
    programs.niri.settings.window-rules = [
      # Default rules
      {
        geometry-corner-radius =
          let
            radius = 20.0;
          in
          {
            top-left = radius;
            top-right = radius;
            bottom-left = radius;
            bottom-right = radius;
          };
        clip-to-geometry = true;
        opacity = 0.93;
      }

      # Picture-in-picture windows
      {
        matches = [
          { title = "^Picture in picture.*$"; }
        ];
        opacity = 1.0;
      }

      # QEMU windows
      {
        matches = [
          { title = "^.* on QEMU/KVM$"; }
        ];
        opacity = 1.0;
      }

      # KDE Connect daemon
      {
        matches = [
          { app-id = "^org\\.kde\\.kdeconnect\\.daemon.*$"; }
        ];
        open-floating = true;
      }

      # Remmina main window (connection list) - keep transparent
      {
        matches = [
          {
            app-id = "org.remmina.Remmina";
            title = "Remmina Remote Desktop Client";
          }
        ];
        opacity = 0.8;
      }
      # Fix staem friend game play notification window
      {
        matches = [
          {
            app-id = "steam";
            title = "^notificationtoasts_\d+_desktop$";
          }
        ];
        open-floating = true;
        default-floating-position = {
          x = 20;
          y = 20;
          relative-to = "bottom-right";
        };
      }
    ]
    ++ opaqueRules;
  };
}
