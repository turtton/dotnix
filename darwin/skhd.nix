{
  services.skhd = {
    enable = true;
    skhdConfig = ''
      # Terminal
      cmd + alt - return : open -na Ghostty

      # ウィンドウを閉じる
      alt + shift - q : osascript -e 'tell application "System Events" to keystroke "w" using command down'
    '';
  };
}
