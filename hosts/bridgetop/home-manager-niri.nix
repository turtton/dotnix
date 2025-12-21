{ lib, ... }:
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
    ./../../home-manager/gui/term/alacritty.nix
    ./../../home-manager/gui/filemanager/dolphin
    # Note: module/niri handles the WM config via packs.niri.enable
  ];

  programs.niri.settings = {
    outputs = {
      "eDP-1" = {
        mode = { width = 2240; height = 1400; refresh = 60.0; };
        position = { x = 0; y = 0; };
        scale = 1.25;
      };
    };
    input.mouse.accel-speed = lib.mkForce 0.05;
    spawn-at-startup = lib.mkAfter [
      { command = ["bitwarden"]; }
      { command = ["keybase-gui"]; }
    ];
  };

  programs.noctalia-shell.settings = {
    bar.monitors = [ "eDP-1" ];
    notifications.monitors = [ "eDP-1" ];
  };
}
