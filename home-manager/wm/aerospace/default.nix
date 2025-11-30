{
  imports = [
    ./key-bindings.nix
  ];
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    userSettings = {
      start-at-login = true;
      gaps = {
        outer = {
          left = 8;
          bottom = 8;
          top = 8;
          right = 8;
        };
        inner = {
          horizontal = 10;
          vertical = 10;
        };
      };
      on-focus-changed = [ "move-mouse window-lazy-center" ];
    };
  };
}
