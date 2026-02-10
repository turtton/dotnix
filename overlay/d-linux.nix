# Reference: https://github.com/colonelpanic8/dotfiles/blob/4e3e75c3e27372f3b7694fc3239bff6013d64ed9/nixos/overlay.nix
{ pkgs, inputs, ... }:
let
  generated = pkgs.callPackage ../_sources/generated.nix { };
in
{
  nixpkgs.overlays = [
    inputs.nix-vscode-extensions.overlays.default
    inputs.rust-overlay.overlays.default
    inputs.rustowl.overlays.default
    inputs.nix-cachyos-kernel.overlays.pinned
    inputs.llm-agents.overlays.default
    (import ./claude-code inputs)
    (import ./fix-dolphin-mime.nix)
    (import ./fix-ime.nix)
    (import ./force-wayland.nix inputs)
    (import ./noto-fonts-cjk-serif.nix)
    (import ./noto-fonts-cjk-sans.nix)
    (import ./noto-fonts.nix)
    (import ./isaacsim.nix)
    (import ./beutl { inherit (generated) beutl beutl-native-deps; })
    (import ./jetbrains-dolphin.nix generated.jetbrains-dolphin)
    (import ./jetbrains-nautilus.nix generated.jetbrains-nautilus)
    (import ./wallpaper-springcity.nix generated.wallpaper-springcity)
    (import ./wifiman-desktop.nix)
    (import ./siketyan-ghr.nix inputs)
    #    (import ./webapp.nix)
  ];
}
