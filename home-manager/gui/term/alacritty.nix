{ pkgs, config, ... }:
let
  # based on tokyo-night https://github.com/zatchheems/tokyo-night-alacritty-theme/blob/main/tokyo-night.toml
  # normal colors
  n_black = "#32344a";
  n_red = "#f7768e";
  n_green = "#9ece6a";
  n_yellow = "#e0af68";
  n_blue = "#7aa2f7";
  n_magenta = "#ad8ee6";
  n_cyan = "#449dab";
  n_white = "#787c99";
  # bright colors
  b_black = "#444b6a";
  b_red = "#ff7a93";
  b_green = "#b9f27c";
  b_yellow = "#ff9e64";
  b_blue = "#7da6ff";
  b_magenta = "#bb9af7";
  b_cyan = "#0db9d7";
  b_white = "#acb0d0";
  # custom colors 
  base = "#1a1b26";
  text = "#a9b1d6";
  # # based on Jolly-kosnole
  # # normal colors
  # n_black = "#1f1d36";
  # n_red = "#9191d5";
  # n_green = "#8be9fd";
  # n_yellow = "#f1fa8c";
  # #n_blue = "#9191d5";
  # n_blue = b_blue;
  # #n_magenta = "#ff557f";
  # n_magenta = b_magenta;
  # n_cyan = "#ff5555";
  # n_white = "#b9bfc7";
  # # bright colors
  # b_black = "#4f607a";
  # b_red = "#9191d5";
  # b_green = "#7b7bb6";
  # b_yellow = "#ffff7f";
  # b_blue = "#ffb86c";
  # b_magenta = "#009ebd";
  # b_cyan = "#bd93f9";
  # b_white = "#7979b3";
  # dim colors
  d_black = "#282647";
  d_red = "#651900";
  d_green = "#00aa7f";
  d_yellow = "#7d7d00";
  d_blue = "#dea05e";
  d_magenta = "#006a80";
  d_cyan = "#c24141";
  d_white = "#7171a8";
  # # custom colors 
  # base = n_black;
  # text = n_white;
  subtext0 = "#A6ADC8";
  rosewater = "#F5E0DC";

  # font
  hack = "Hack Nerd Font";
in
{
  home.packages = [
    pkgs.alacritty.terminfo
  ];
  home.sessionVariables.TERMINFO_DIRS = "${config.home.homeDirectory}/.nix-profile/share/terminfo";
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 4;
          y = 2;
        };
        opacity = 0.93;
        blur = true;
      };
      keyboard = {
        bindings = [
          { key = "V"; mods = "Control | Shift"; action = "Paste"; }
        ];
      };
      colors = {
        primary = {
          background = base;
          foreground = text;
          #dim_foreground = b_blue;
          #bright_foreground = d_cyan;
        };
        cursor = {
          text = base;
          cursor = rosewater;
        };
        vi_mode_cursor = {
          text = base;
          cursor = text;
        };
        search = {
          matches = {
            foreground = base;
            background = subtext0;
          };
          focused_match = {
            foreground = base;
            background = "#A6E3A1";
          };
        };
        footer_bar = {
          background = base;
          foreground = subtext0;
        };
        hints = {
          start = {
            foreground = base;
            background = "#F9E2AF";
          };
          end = {
            foreground = base;
            background = subtext0;
          };
        };
        selection = {
          text = base;
          background = rosewater;
        };
        normal = {
          black = n_black;
          red = n_red;
          green = n_green;
          yellow = n_yellow;
          blue = n_blue;
          magenta = n_magenta;
          cyan = n_cyan;
          white = n_white;
        };
        bright = {
          black = b_black;
          red = b_red;
          green = b_green;
          yellow = b_yellow;
          blue = b_blue;
          magenta = b_magenta;
          cyan = b_cyan;
          white = b_white;
        };
        dim = {
          black = d_black;
          red = d_red;
          green = d_green;
          yellow = d_yellow;
          blue = d_blue;
          magenta = d_magenta;
          cyan = d_cyan;
          white = d_white;
        };
        indexed_colors = [
          { index = 16; color = "#FAB387"; }
          { index = 17; color = rosewater; }
        ];
      };
      font = {
        normal = {
          family = hack;
          style = "Regular";
        };
        bold = {
          family = hack;
          style = "Bold";
        };
        italic = {
          family = hack;
          style = "Italic";
        };
        bold_italic = {
          family = hack;
          style = "Bold Italic";
        };
        size = 10.0;
      };
    };
  };
}
