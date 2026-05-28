{
  services.skhd = {
    enable = true;
    skhdConfig = ''
      # Terminal
      cmd + alt - return : open -an ghostty.app
    '';
  };
}
