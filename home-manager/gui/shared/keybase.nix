{ pkgs, ... }: {
  services = {
    keybase.enable = true;
    kbfs.enable = true;
  };
  home.packages = with pkgs; [ keybase-gui ];
}
