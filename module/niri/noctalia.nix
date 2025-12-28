{ lib, config, ... }:
let
  cfg = config.packs.niri;
in
{
  config = lib.mkIf cfg.enable {
    programs.niri.settings = {
      # Allows notification actions and window activation from Noctalia.
      debug.honor-xdg-activation-with-invalid-serial = { };
      # https://docs.noctalia.dev/getting-started/compositor-settings/#option-2-stationary-wallpaper
      layer-rules = [
        {
          matches = [ { namespace = "^noctalia-overview*"; } ];
          place-within-backdrop = true;
        }
      ];

      binds = {
        "Mod+V".action.spawn = [
          "noctalia-shell"
          "ipc"
          "call"
          "launcher"
          "clipboard"
        ];
        "Mod+d".action.spawn = [
          "noctalia-shell"
          "ipc"
          "call"
          "launcher"
          "toggle"
        ];
        "Mod+Shift+d".action.spawn = [
          "noctalia-shell"
          "ipc"
          "call"
          "launcher"
          "calculator"
        ];
      };
    };
  };
}
