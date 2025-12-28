{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.packs.niri;
in
{
  config = lib.mkIf cfg.enable {
    programs.niri.settings = {
      environment = {
        XMODIFIERS = "@im=fcitx";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "gtk3";
        QT_STYLE_OVERRIDE = "kvantum";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        NIXOS_OZONE_WL = "1";
        GIO_MODULE_DIR = "${pkgs.glib-networking}/lib/gio/modules/";
      };

      input = {
        keyboard = {
          xkb = {
            layout = "us";
          };
          repeat-delay = 300;
          repeat-rate = 30;
        };

        mouse = {
          accel-speed = lib.mkDefault (-0.5);
          accel-profile = "flat";
        };

        focus-follows-mouse = {
          enable = true;
        };
      };

      layout = {
        gaps = 5;
        border = {
          enable = true;
          width = 2;
          active.color = "#82aaff";
          inactive.color = "#222436";
        };
        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
      };

      cursor = {
        theme = "GoogleDot-Black";
        size = 24;
      };

      prefer-no-csd = true;

      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # TODO: Add animations after confirming correct niri-flake format

      spawn-at-startup = [
        {
          command = [
            "fcitx5"
            "-D"
          ];
        }
        {
          command = [
            "systemctl"
            "--user"
            "start"
            "hyprpolkitagent"
          ];
        }
        {
          command = [
            "wl-paste"
            "--watch"
            "cliphist"
            "store"
          ];
        }
        {
          command = [
            "${pkgs.cliphist}/bin/cliphist"
            "wipe"
          ];
        }
        { command = [ "${pkgs.gitify}/bin/gitify" ]; }
        {
          command = [ "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1" ];
        }
      ];
    };
  };
}
