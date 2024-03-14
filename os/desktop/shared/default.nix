{
  imports = [
    ./fonts.nix
    ./sound.nix
  ];
  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;
    # Configure keymap in X11
    layout = "us";
    xkbVariant = "";
  };
}