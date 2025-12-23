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
    ./../../home-manager/gui/dev/local-llm.nix
    ./../../home-manager/gui/dev/creative.nix
    ./../../home-manager/gui/game
    ./../../home-manager/gui/term/alacritty.nix
    ./../../home-manager/gui/term/ghostty.nix
    ./../../home-manager/gui/filemanager/dolphin
    # Note: module/niri handles the WM config via packs.niri.enable
  ];

  programs.niri.settings = {
    outputs = {
      "DP-1" = {
        mode = { width = 1920; height = 1080; refresh = 144.0; };
        position = { x = 0; y = 0; };
        scale = 1.0;
      };
      "DP-2" = {
        mode = { width = 1920; height = 1080; refresh = 60.0; };
        position = { x = 1920; y = 0; };
        scale = 1.0;
      };
      "DP-3" = {
        mode = { width = 1920; height = 1080; refresh = 60.0; };
        position = { x = -1920; y = 0; };
        scale = 1.0;
      };
    };
    input.mouse.accel-speed = lib.mkForce (-0.45);
    spawn-at-startup = lib.mkAfter [
      { command = ["bitwarden"]; }
      { command = ["vesktop"]; }
      { command = ["steam" "-silent"]; }
      { command = ["keybase-gui"]; }
    ];
  };

  programs.noctalia-shell.settings = {
    bar.monitors = [ "DP-1" ];
    notifications.monitors = [ "DP-1" ];
  };
}
