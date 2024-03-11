{
  # Enable the X11 windowing system.
  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;
    # Enable the KDE Plasma Desktop Environment.
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;
  };
}