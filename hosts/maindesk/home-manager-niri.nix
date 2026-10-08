{
  config,
  lib,
  osConfig,
  ...
}:
{
  imports = [
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/dev
    (import ./../../home-manager/cli/git.nix {
      userName = "turtton";
      userEmail = "top.gear7509@turtton.net";
      signingKey = "8152FC5D0B5A76E1";
    })
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/shared
    ./../../home-manager/gui/dev
    ./../../home-manager/gui/dev/local-llm.nix
    ./../../home-manager/gui/dev/creative.nix
    ./../../home-manager/gui/game
    ./../../home-manager/gui/term/alacritty.nix
    ./../../home-manager/gui/term/ghostty.nix
    ./../../home-manager/gui/filemanager/dolphin
  ];

  programs.niri.settings = {
    outputs = {
      "ASUSTek COMPUTER INC XG32UCG W2LMTF052146 " = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 120.0;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 1.2;
      };
      "ViewSonic Corporation VX2458-mhd VK0184700653" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 60.0;
        };
        position = {
          x = 0;
          y = -1080;
        };
        scale = 1.0;
      };
      "Xiaomi Corporation Mi Monitor Unknown" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 60.0;
        };
        position = {
          x = -1080;
          y = -160;
        };
        scale = 1.0;
        transform.rotation = 270;
      };
      "Dell Inc. DELL E2210H J232R9A5091L" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 60.0;
        };
        position = {
          x = -1080 - 1920;
          y = 600;
        };
        scale = 1.0;
      };
    };
    input.mouse.accel-speed = lib.mkForce (-0.45);
    spawn-at-startup = lib.mkAfter [
      { command = [ "bitwarden" ]; }
      { command = [ "vesktop" ]; }
      {
        command = [
          "steam"
          "-silent"
        ];
      }
      { command = [ "keybase-gui" ]; }
    ];
  };

  programs.rclone = {
    enable = true;
    remotes.nextcloud = {
      config = {
        type = "webdav";
        url = "https://nextcloud.taile2777.ts.net/remote.php/dav/files/Music-A";
        vendor = "nextcloud";
        user = "Music-A";
      };
      secrets.pass = osConfig.sops.secrets.nextcloud-music-password.path;
      mounts.Music = {
        enable = true;
        mountPoint = "${config.home.homeDirectory}/Music/Nextcloud";
        options = {
          read-only = true;
          vfs-cache-max-size = "20G";
          vfs-cache-max-age = "720h";
        };
      };
    };
  };
  # Tailscale (a system unit) cannot be ordered against from a user unit, so retry until it is up.
  systemd.user.services."rclone-mount:Music@nextcloud" = {
    Unit.StartLimitIntervalSec = 0;
    Service.RestartSec = 10;
  };

  programs.noctalia.settings = {
    bar.main.monitor.primary = {
      match = "DP-1";
      enabled = true;
    };
    notification.monitors = [ "DP-1" ];
  };
}
