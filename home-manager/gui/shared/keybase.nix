{ pkgs, ... }: {
  services.keybase.enable = true;
  home.packages = with pkgs; [ keybase-gui ];
}
