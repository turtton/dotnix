{ pkgs, hostPlatform, ... }:
let
  ghostty = if hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

  # GTK版のタブバーを細くするカスタムCSS。
  gtkCss = pkgs.writeText "ghostty-gtk.css" ''
    tabbar tabbox {
      min-height: 18px;
      padding-top: 0;
      padding-bottom: 0;
    }

    tabbar tab button.image-button {
      min-height: 16px;
      min-width: 16px;
    }
  '';
in
{
  home.packages = [
    ghostty.terminfo
  ];
  programs.ghostty = {
    enable = true;
    package = ghostty;
    installVimSyntax = true;
    settings = {
      theme = "Catppuccin Mocha";
      font-family = "Hack Nerd Font";
      font-size = 10;
      background-opacity = 0.7;
      background-blur = "macos-glass-clear";
      macos-titlebar-style = "transparent";
      window-save-state = "never";
      quit-after-last-window-closed = true;

      # 範囲選択した時点でシステムクリップボードにコピー
      copy-on-select = "clipboard";

      gtk-custom-css = [ "${gtkCss}" ];

      # ペイン分割 for Linux
      keybind = [
        "ctrl+shift+d=new_split:right"
        "ctrl+shift+e=new_split:down"
        "ctrl+shift+enter=toggle_split_zoom"
        "ctrl+alt+left=goto_split:left"
        "ctrl+alt+right=goto_split:right"
        "ctrl+alt+up=goto_split:up"
        "ctrl+alt+down=goto_split:down"
        "ctrl+shift+h=previous_tab"
        "ctrl+shift+l=next_tab"
      ];
    };
  };
}
