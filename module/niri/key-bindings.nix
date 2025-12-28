{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.packs.niri;
in
{
  config = lib.mkIf cfg.enable {
    programs.niri.settings.binds = with pkgs; {
      # Basic window management
      "Mod+Return".action.spawn = [ "alacritty" ];
      "Mod+Shift+Q".action.close-window = { };
      "Mod+F".action.fullscreen-window = { };
      "Mod+Alt+F".action.set-column-width = "100%";
      "Mod+Shift+F".action.toggle-window-floating = { };
      "Mod+Shift+E".action.spawn = [ "wlogout" ];

      # Noctalia bindings are in module/niri/noctalia.nix
      "Mod+C".action.spawn = [
        "sh"
        "-c"
        "${zenity}/bin/zenity --entry --text='Enter text:' | sed -z 's/\\n$//' | wl-copy"
      ];

      # Focus movement (Alt + arrows/hjkl)
      "Alt+Left".action.focus-column-left = { };
      "Alt+Down".action.focus-window-down = { };
      "Alt+Up".action.focus-window-up = { };
      "Alt+Right".action.focus-column-right = { };
      "Alt+h".action.focus-column-left = { };
      "Alt+j".action.focus-window-down = { };
      "Alt+k".action.focus-window-up = { };
      "Alt+l".action.focus-column-right = { };

      # Window movement (Mod + arrows/hjkl)
      "Mod+Left".action.move-column-left = { };
      "Mod+Down".action.move-window-down = { };
      "Mod+Up".action.move-window-up = { };
      "Mod+Right".action.move-column-right = { };
      "Mod+h".action.move-column-left = { };
      "Mod+j".action.move-window-down = { };
      "Mod+k".action.move-window-up = { };
      "Mod+l".action.move-column-right = { };

      # Window resizing
      "Mod+Shift+Left".action.set-window-width = "+10%";
      "Mod+Shift+Right".action.set-window-width = "-10%";
      "Mod+Shift+h".action.set-window-width = "-10%";
      "Mod+Shift+l".action.set-window-width = "+10%";

      # Column management
      "Mod+BracketLeft".action.consume-window-into-column = { };
      "Mod+BracketRight".action.expel-window-from-column = { };

      # Workspace switching (Mod + 1-9)
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      # Move to workspace (Mod + Shift + 1-9)
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;

      "Mod+Shift+Down".action.move-column-to-workspace-down = { };
      "Mod+Shift+Up".action.move-column-to-workspace-up = { };
      "Mod+Shift+j".action.move-column-to-workspace-down = { };
      "Mod+Shift+k".action.move-column-to-workspace-up = { };

      # Workspace navigation (Mod + Ctrl + H/L)
      "Mod+Ctrl+j".action.focus-workspace-down = { };
      "Mod+Ctrl+k".action.focus-workspace-up = { };
      "Mod+Ctrl+Down".action.focus-workspace-down = { };
      "Mod+Ctrl+Up".action.focus-workspace-up = { };

      # Monitor management
      "Mod+Tab".action.focus-monitor-next = { };
      "Mod+Shift+Tab".action.move-column-to-monitor-next = { };

      #Overview
      "Alt+Tab".action.toggle-overview = { };

      # Screenshots
      "Print".action.screenshot-screen = { };
      "Mod+Print".action.screenshot-window = { };
      "Mod+Shift+s".action.screenshot = { };

      # Media control
      "XF86AudioPlay".action.spawn = [
        "${playerctl}/bin/playerctl"
        "play-pause"
      ];
      "XF86AudioPrev".action.spawn = [
        "${playerctl}/bin/playerctl"
        "previous"
      ];
      "XF86AudioNext".action.spawn = [
        "${playerctl}/bin/playerctl"
        "next"
      ];

      # Volume control
      "XF86AudioMute".action.spawn = [
        "${pamixer}/bin/pamixer"
        "-t"
      ];
      "XF86AudioRaiseVolume".action.spawn = [
        "${pamixer}/bin/pamixer"
        "-i"
        "10"
      ];
      "XF86AudioLowerVolume".action.spawn = [
        "${pamixer}/bin/pamixer"
        "-d"
        "10"
      ];

      # Brightness control
      "XF86MonBrightnessUp".action.spawn = [
        "${brightnessctl}/bin/brightnessctl"
        "set"
        "+10%"
      ];
      "XF86MonBrightnessDown".action.spawn = [
        "${brightnessctl}/bin/brightnessctl"
        "set"
        "10%-"
      ];

      # Mouse workspace navigation
      "Mod+WheelScrollDown".action.focus-workspace-down = { };
      "Mod+WheelScrollUp".action.focus-workspace-up = { };
      "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
      "Mod+Shift+WheelScrollDown".action.focus-column-right = { };

      # Color picker
      "Mod+Shift+c".action.spawn = [
        "${hyprpicker}/bin/hyprpicker"
        "--autocopy"
      ];
    };
  };
}
