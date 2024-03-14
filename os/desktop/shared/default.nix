{
  imports = [
    ./sound
    ./fonts.nix
  ];
  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;
    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };
}