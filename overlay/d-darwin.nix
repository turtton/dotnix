# Reference: https://github.com/colonelpanic8/dotfiles/blob/4e3e75c3e27372f3b7694fc3239bff6013d64ed9/nixos/overlay.nix
{ pkgs, ... }:
let
  generated = pkgs.callPackage ../_sources/generated.nix { };
in
{
  nixpkgs.overlays = [
    (import ./ghr.nix generated.ghr)
  ];
}
