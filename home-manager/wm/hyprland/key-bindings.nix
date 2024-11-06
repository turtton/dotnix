{
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    "$subMod" = "ALT";
    "$term" = "alacritty";
    bind = [
      "$mainMod, Return, exec, $term"
      "$mainMod SHIFT, Q, killactive"
      "$mainMod SHIFT, E, exec, eww open --toggle poweroptions"
      "$mainMod, F, fullscreen"
      "$mainMod SHIFT, F, togglefloating"

      # move focus
      "$subMod, left, movefocus, left"
      "$subMod, down, movefocus, down"
      "$subMod, up, movefocus, up"
      "$subMod, right, movefocus, right"
      "$subMod, h, movefocus, l"
      "$subMod, j, movefocus, d"
      "$subMod, k, movefocus, u"
      "$subMod, l, movefocus, r"
      "$subMod, Tab, cyclenext"
      "$subMod SHIFT, Tab, cyclenext, prev"

      # move window
      "$mainMod, left, movewindow, left"
      "$mainMod, down, movewindow, down"
      "$mainMod, up, movewindow, up"
      "$mainMod, right, movewindow, right"
      "$mainMod, h, movewindow, l"
      "$mainMod, j, movewindow, d"
      "$mainMod, k, movewindow, u"
      "$mainMod, l, movewindow, r"

      # switch workspace
      "$mainMod, 1, exec, workspace 1"
      "$mainMod, 2, exec, workspace 2"
      "$mainMod, 3, exec, workspace 3"
      "$mainMod, 4, exec, workspace 4"
      "$mainMod, 5, exec, workspace 5"
      "$mainMod, 6, exec, workspace 6"
      "$mainMod, 7, exec, workspace 7"
      "$mainMod, 8, exec, workspace 8"
      "$mainMod, 9, exec, workspace 9"
      "$mainMod, 10, exec, workspace 10"
      "$mainMod CTRL, right, workspace, m+1"
      "$mainMod CTRL, left, workspace, m-1"
      "$mainMod CTRL, h, workspace, m+1"
      "$mainMod CTRL, l, workspace, m-1"
      "$mainMod, mouse_down, workspace, m+1"
      "$mainMod, mouse_up, workspace, m-1"

      # move window to workspace
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 10, movetoworkspace, 10"
      "$mainMod SHIFT, right, movetoworkspace, m+1"
      "$mainMod SHIFT, left, movetoworkspace, m-1"
      "$mainMod SHIFT, h, movetoworkspace, m+1"
      "$mainMod SHIFT, l, movetoworkspace, m-1"

      # toggle monitor
      "$mainMod, Tab, exec, hyprctl monitors -j|jq 'map(select(.focused|not).activeWorkspace.id)[0]'|xargs hyprctl dispatch workspace"

      # screenshot
      ", Print, exec, grimblast --notify copy output"
      ''
        $mainMod, Print, exec, grimblast --notify copysave output "$HOME/Screenshots/$(date +%Y-%m-%dT%H:%M:%S).png"''
      ''
        $mainMod SHIFT, s, exec, grimblast --notify copysave area "$HOME/Screenshots/$(date +%Y-%m-%dT%H:%M:%S).png"''

      # launcher
      "$mainMod, d, exec, rofi -show drun"
      "$mainMod, period, exec, rofi -modi emoji -show emoji"

      # color picker
      "$mainMod SHIFT, c, exec, hyprpicker --autocopy"

      # screen lock
      "$mainMod, l, exec, swaylock --image ~/.config/hypr/wallpaper/talos-2.jpg"

      # system
      "$mainMod, x, exec, systemctl suspend"
    ];
    bindm = [
      # move/resize window
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];
    bindl = [
      # media control
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
      ", XF86AudioNext, exec, playerctl next"

      # volume control: mute
      ", XF86AudioMute, exec, pamixer -t"
    ];
    bindle = [
      # volume control
      ", XF86AudioRaiseVolume, exec, pamixer -i 10"
      ", XF86AudioLowerVolume, exec, pamixer -d 10"

      # brightness control
      ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
      ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
    ];
  };
}
