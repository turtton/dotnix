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
  };
}
