# Reference: https://github.com/colonelpanic8/dotfiles/blob/4e3e75c3e27372f3b7694fc3239bff6013d64ed9/nixos/overlay.nix
{ pkgs, inputs, ... }:
let
  generated = pkgs.callPackage ../_sources/generated.nix { };
in
{
  nixpkgs.overlays = [
    (import ./fix-ime.nix)
    (import ./force-wayland.nix)
    (import ./noto-fonts-cjk-serif.nix)
    (import ./noto-fonts-cjk-sans.nix)
    (import ./noto-fonts.nix)
    (import ./ghr.nix generated.ghr)
    inputs.rust-overlay.overlays.default
    (import ./rustowl.nix generated.rustowl)
    (import ./jetbrains-dolphin.nix generated.jetbrains-dolphin)
    (import ./jetbrains-nautilus.nix generated.jetbrains-nautilus)
    (import ./wallpaper-springcity.nix generated.wallpaper-springcity)
    #    (import ./webapp.nix)
  ];
}
