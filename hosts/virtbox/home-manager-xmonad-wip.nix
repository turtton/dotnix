{ lib, ... }:
{
  imports = [
    ./../../home-manager/cli/shared
    ./../../home-manager/cli/shell/zsh
    ./../../home-manager/gui/shared
    ./../../home-manager/gui/term/wezterm
    ./../../home-manager/wm/xmonad
    # ./../../home-manager/gui/game
  ];
}
