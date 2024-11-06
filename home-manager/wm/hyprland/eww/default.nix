{ pkgs, ... }: {
  programs.eww = {
    enable = true;
    enableZshIntegration = true;
    configDir = ./config;
  };
  home.packages = with pkgs; [
    python312
    jq
    betterlockscreen
    socat
  ];
}
