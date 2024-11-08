{ pkgs, inputs, system, ... }: {
  imports = [
    ./dunst.nix
    ./eww
    ./key-bindings.nix
    ./settings.nix
    #./wofi.nix
    ./rofi
    ./waybar
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    plugins = [
      inputs.split-monitor-workspaces.packages.${system}.split-monitor-workspaces
    ];
    package = inputs.hyprland.packages.${system}.hyprland;
  };

  home.packages = with pkgs; [
    tokyonight-gtk-theme
    lxappearance
    brightnessctl # screen brightness
    grimblast # screenshot
    hyprpicker # color picker
    pamixer # pulseaudio mixer
    playerctl # media player control
    swww # wallpaper
    wayvnc # vnc server
    wev # key event watcher
    wf-recorder # screen recorder
    wl-clipboard # clipboard manager
    kdePackages.qt6ct
    libsForQt5.qt5ct
    polkit_gnome # password prompt
  ];

  xdg.userDirs.createDirectories = true;
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
