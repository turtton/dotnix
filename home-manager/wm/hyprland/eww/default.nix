{ pkgs, ... }: {
  programs.eww = {
    enable = true;
    enableZshIntegration = true;
    configDir = ./config;
  };
  home.packages = with pkgs; [
    (python312.withPackages (ps: with ps; [
			requests
		]))
    jq
    betterlockscreen
    socat
  ];
}
