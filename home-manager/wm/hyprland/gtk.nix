{ pkgs, ... }: {
  home.packages = with pkgs; [
    tokyonight-gtk-theme
    lxappearance
  ];
  xdg.configFile =
    let
      settings = pkgs.writeText "settings.ini" ''
                [Settings]
        				gtk-im-module = fcitx
                gtk-application-prefer-dark-theme = 1
                gtk-theme-name = Tokyonight-Dark
                gtk-icon-theme-name = Tokyonight-Dark
                gtk-cursor-theme-name = Tokyonight-Dark
      '';
    in
    {
      "gtk-3.0/settings.ini".source = settings;
      "gtk-4.0/settings.ini".source = settings;
      "gtk-4.0/gtk.css".text = ''
        			/**
        			* GTK 4 reads the theme configured by gtk-theme-name, but ignores it.
        			* It does however respect user CSS, so import the theme from here.
        			**/
        			@import url("file://${pkgs.tokyonight-gtk-theme}/share/themes/Tokyonight-Dark/gtk-4.0/gtk.css");
        		'';
    };
}
