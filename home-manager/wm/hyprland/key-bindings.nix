{ pkgs, ... }: {
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    "$subMod" = "ALT";
    "$term" = "alacritty";
    "$fileManager" = "dolphin";
    bind = [
      "$mainMod, Return, exec, $term"
      "$mainMod SHIFT, Q, killactive"
      "$mainMod SHIFT, E, exec, ${pkgs.hyprpanel}/bin/hyprpanel -t powerdropdownmenu"
      "$mainMod, F, fullscreen"
      "$mainMod SHIFT, F, togglefloating"
      "$mainMod SHIFT, P, pin"
      "$mainMod, V, exec, rofi -modi clipboard:${pkgs.cliphist}/bin/cliphist-rofi-img -show clipboard -show-icons -theme-str '##element-icon {size: 5ch; }'"
      "$mainMod, P, exec, ${pkgs.rofi-rbw-wayland}/bin/rofi-rbw"
      "$mainMod, C, exec, ${pkgs.zenity}/bin/zenity --entry --text='Enter text:' | wl-copy"

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

      # switch activeWorkspace
      # split-monitor-workspaces
      "$mainMod			, 1			, split-workspace, 1"
      "$mainMod			, 2			, split-workspace, 2"
      "$mainMod			, 3			, split-workspace, 3"
      "$mainMod			, 4			, split-workspace, 4"
      "$mainMod			, 5			, split-workspace, 5"
      "$mainMod			, 6			, split-workspace, 6"
      "$mainMod			, 7			, split-workspace, 7"
      "$mainMod			, 8			, split-workspace, 8"
      "$mainMod			, 9			, split-workspace, 9"
      "$mainMod CTRL, right	,	split-cycleworkspaces, +1"
      "$mainMod CTRL, left	,	split-cycleworkspaces, -1"
      "$mainMod CTRL, l			,	split-cycleworkspaces, +1"
      "$mainMod CTRL, h			,	split-cycleworkspaces, -1"
      "$mainMod, mouse_down	,	split-cycleworkspaces, +1"
      "$mainMod, mouse_up		,	split-cycleworkspaces, -1"
      # # Normal
      # "$mainMod			, 1			, workspace, 1"
      # "$mainMod			, 2			, workspace, 2"
      # "$mainMod			, 3			, workspace, 3"
      # "$mainMod			, 4			, workspace, 4"
      # "$mainMod			, 5			, workspace, 5"
      # "$mainMod			, 6			, workspace, 6"
      # "$mainMod			, 7			, workspace, 7"
      # "$mainMod			, 8			, workspace, 8"
      # "$mainMod			, 9			, workspace, 9"
      # "$mainMod CTRL, right	,	workspace, m+1"
      # "$mainMod CTRL, left	,	workspace, m-1"
      # "$mainMod CTRL, h			,	workspace, m+1"
      # "$mainMod CTRL, l			,	workspace, m-1"
      # "$mainMod, mouse_down	,	workspace, m+1"
      # "$mainMod, mouse_up		,	workspace, m-1"

      # move window to workspace
      # split-monitor-workspaces
      "$mainMod SHIFT, 1		, split-movetoworkspace, 1"
      "$mainMod SHIFT, 2		, split-movetoworkspace, 2"
      "$mainMod SHIFT, 3		, split-movetoworkspace, 3"
      "$mainMod SHIFT, 4		, split-movetoworkspace, 4"
      "$mainMod SHIFT, 5		, split-movetoworkspace, 5"
      "$mainMod SHIFT, 6		, split-movetoworkspace, 6"
      "$mainMod SHIFT, 7		, split-movetoworkspace, 7"
      "$mainMod SHIFT, 8		, split-movetoworkspace, 8"
      "$mainMod SHIFT, 9		, split-movetoworkspace, 9"
      # Normal
      # "$mainMod SHIFT, 1		, movetoworkspace, 1"
      # "$mainMod SHIFT, 2		, movetoworkspace, 2"
      # "$mainMod SHIFT, 3		, movetoworkspace, 3"
      # "$mainMod SHIFT, 4		, movetoworkspace, 4"
      # "$mainMod SHIFT, 5		, movetoworkspace, 5"
      # "$mainMod SHIFT, 6		, movetoworkspace, 6"
      # "$mainMod SHIFT, 7		, movetoworkspace, 7"
      # "$mainMod SHIFT, 8		, movetoworkspace, 8"
      # "$mainMod SHIFT, 9		, movetoworkspace, 9"

      "$mainMod SHIFT, right, movetoworkspace, m+1"
      "$mainMod SHIFT, left	, movetoworkspace, m-1"
      "$mainMod SHIFT, h		, movetoworkspace, m-1"
      "$mainMod SHIFT, l		, movetoworkspace, m+1"

      # toggle monitor
      "$mainMod, Tab, exec, hyprctl monitors -j|jq 'map(select(.focused|not).activeWorkspace.id)[0]'|xargs hyprctl dispatch workspace"

      # screenshot
      '', Print, exec, grimblast save output - | swappy -f - -o /tmp/screenshot.png && zenity --question --text="Save?" && cp /tmp/screenshot.png $HOME/Pictures/$(date +%Y-%m-%dT%H:%M:%S).png''
      ''
        $mainMod, Print, exec, grimblast save active - | swappy -f - -o /tmp/screenshot.png && zenity --question --text="Save?" && cp /tmp/screenshot.png "$HOME/Pictures/$(date +%Y-%m-%dT%H:%M:%S).png"''
      ''
        $mainMod SHIFT, s, exec, grimblast save area - | swappy -f - -o /tmp/screenshot.png && zenity --question --text="Save?" && cp /tmp/screenshot.png "$HOME/Pictures/$(date +%Y-%m-%dT%H:%M:%S).png"''

      # launcher
      "$mainMod, d, exec, rofi -show drun"
      "$mainMod, period, exec, bemoji"

      # color picker
      "$mainMod SHIFT, c, exec, hyprpicker --autocopy"

      # screen lock
      "$mainMod CTRL SHIFT, l, exec, hyprlock"

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
