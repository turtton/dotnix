{ config, ... }:
let
  lock-cmd = "noctalia-shell ipc call lockScreen lock";
in
{
  services.swayidle = {
    enable = true;
    events = {
      before-sleep = lock-cmd;
      lock = lock-cmd;
    };
    timeouts = [
      {
        timeout = 900;
        command = "niri msg action power-off-monitors";
      }
      {
        timeout = 910;
        command = lock-cmd;
      }
    ];
  };
}
