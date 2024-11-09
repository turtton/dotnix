{ pkgs, ... }: {
  home.packages = with pkgs; [
    eog # Image viewer
  ];
}
