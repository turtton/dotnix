{username, pkgs, ...} :{
  # Enable the X11 windowing system.
  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;
    # Enable the KDE Plasma Desktop Environment.
    displayManager.sddm.enable = true;
    
    desktopManager.plasma5.enable = true;
  };
  users.users."${username}".packages = with pkgs; [
    latte-dock
    libsForQt5.applet-window-buttons
  ];
}