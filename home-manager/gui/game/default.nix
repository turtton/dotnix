{ pkgs, ... }: {
  home.packages = with pkgs; [
    # minecraft-launcher marked boroken https://github.com/NixOS/nixpkgs/pull/299645
    # minecraft
    prismlauncher
    lutris
    osu-lazer
  ];
}
