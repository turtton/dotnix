{ pkgs, ... }: {
  home.packages = with pkgs; [
    minecraft
    prismlauncher
    lutris
  ];
}
