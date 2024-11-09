# Reference: https://github.com/colonelpanic8/dotfiles/blob/4e3e75c3e27372f3b7694fc3239bff6013d64ed9/nixos/overlay.nix
{ pkgs, ... }:
let
  generated = pkgs.callPackage ../_sources/generated.nix { };
in
{
  nixpkgs.overlays = [
    (import ./noto-fonts-cjk-serif.nix)
    (import ./noto-fonts-cjk-sans.nix)
    (import ./noto-fonts.nix)
    (import ./ghr.nix generated.ghr)
    (import ./hyprpanel-tokyonight.nix generated.hyprpanel-tokyonight)
    (import ./jetbrains-dolphin.nix generated.jetbrains-dolphin)
    (import ./jetbrains-nautilus.nix generated.jetbrains-nautilus)
    (import ./wallpaper-springcity.nix generated.wallpaper-springcity)
  ];
}
