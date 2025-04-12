{ theme, ... }:
with theme.xcolors;
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 1;
        timeout = 10;
        offset = "30x30";
        transparency = 10;
        foreground = "#c8d3f5";
        background = "#1b1d2b";
        frame_color = "#1b1d2b";
        corner_radius = 10;
        font = "Noto Sans CJK JP";
      };
      urgency_critical = {
        frame_color = "#ff757f";
      };
    };
  };
}
