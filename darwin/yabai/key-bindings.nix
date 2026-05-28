{ lib, ... }:
{
  services.skhd.skhdConfig = lib.mkAfter ''
    # Close window
    alt + shift - q : yabai -m window --close

    # Fullscreen / Float
    alt - f : yabai -m window --toggle zoom-fullscreen
    alt + shift - f : yabai -m window --toggle float --grid 4:4:1:1:2:2

    # Focus movement (alt + hjkl)
    alt - h : yabai -m window --focus west
    alt - j : yabai -m window --focus south
    alt - k : yabai -m window --focus north
    alt - l : yabai -m window --focus east

    # Window swap (alt + shift + hjkl)
    alt + shift - h : yabai -m window --swap west
    alt + shift - j : yabai -m window --swap south
    alt + shift - k : yabai -m window --swap north
    alt + shift - l : yabai -m window --swap east

    # Window resize (alt + ctrl + hjkl)
    alt + ctrl - h : yabai -m window --resize left:-50:0
    alt + ctrl - l : yabai -m window --resize right:50:0
    alt + ctrl - j : yabai -m window --resize bottom:0:50
    alt + ctrl - k : yabai -m window --resize top:0:-50

    # Space focus (alt + 1-9)
    alt - 1 : yabai -m space --focus 1
    alt - 2 : yabai -m space --focus 2
    alt - 3 : yabai -m space --focus 3
    alt - 4 : yabai -m space --focus 4
    alt - 5 : yabai -m space --focus 5
    alt - 6 : yabai -m space --focus 6
    alt - 7 : yabai -m space --focus 7
    alt - 8 : yabai -m space --focus 8
    alt - 9 : yabai -m space --focus 9

    # Move window to space (alt + shift + 1-9)
    alt + shift - 1 : yabai -m window --space 1
    alt + shift - 2 : yabai -m window --space 2
    alt + shift - 3 : yabai -m window --space 3
    alt + shift - 4 : yabai -m window --space 4
    alt + shift - 5 : yabai -m window --space 5
    alt + shift - 6 : yabai -m window --space 6
    alt + shift - 7 : yabai -m window --space 7
    alt + shift - 8 : yabai -m window --space 8
    alt + shift - 9 : yabai -m window --space 9

    # Monitor focus
    alt - tab : yabai -m display --focus next || yabai -m display --focus first

    # Move window to monitor
    alt + shift - tab : yabai -m window --display next || yabai -m window --display first

    # Balance tree
    alt + shift - 0 : yabai -m space --balance

    # Toggle split direction
    alt - e : yabai -m window --toggle split
  '';
}
