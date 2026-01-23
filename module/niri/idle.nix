{
  config,
  lib,
  ...
}:
let
  cfg = config.packs.niri;
  lock-cmd = "noctalia-shell ipc call lockScreen lock";
  monitor-on = "niri msg action power-on-monitors";
  monitor-off = "niri msg action power-off-monitors";
in
{
  config = lib.mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      events = {
        before-sleep = lock-cmd;
        after-resume = monitor-on;
        lock = lock-cmd;
      };
      timeouts = [
        {
          timeout = 900;
          command = monitor-off;
          resumeCommand = monitor-on;
        }
        {
          timeout = 910;
          command = lock-cmd;
        }
      ];
    };
  };
}
