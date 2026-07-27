{
  imports = [
    ./key-bindings.nix
  ];

  services.yabai = {
    enable = true;
    config = {
      layout = "bsp";
      window_placement = "second_child";

      # Gaps
      top_padding = 5;
      bottom_padding = 5;
      left_padding = 5;
      right_padding = 5;
      window_gap = 5;

      # Mouse
      mouse_follows_focus = "on";
      focus_follows_mouse = "autofocus";
      mouse_modifier = "cmd";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";

      # Window appearance
      window_opacity = "off";
      split_ratio = 0.5;
      auto_balance = "off";
    };

    # Ghostty のウィンドウ作成/破棄時にタイル計算がずれるため、
    # レイアウトの再適用を促す。label 付きにして yabairc 再読込時の重複登録を防ぐ
    extraConfig = ''
      yabai -m signal --add \
        event=window_created \
        app='^Ghostty$' \
        label='ghostty_window_created_relayout' \
        action='yabai -m space --layout bsp'
      yabai -m signal --add \
        event=window_destroyed \
        app='^Ghostty$' \
        label='ghostty_window_destroyed_relayout' \
        action='yabai -m space --layout bsp'
    '';
  };
}
