{ ... }:
let
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
  programs.niri.settings.window-rules = [
    # Default opacity for all windows
    {
      opacity = 0.8;
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

    # Remmina connected windows
    {
      matches = [
        {
          app-id = "org.remmina.Remmina";
          title = "^(?!Remmina$).*";
        }
      ];
      opacity = 1.0;
    }
  ]
  ++ opaqueRules;
}
