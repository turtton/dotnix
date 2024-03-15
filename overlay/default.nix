# Reference: https://github.com/colonelpanic8/dotfiles/blob/4e3e75c3e27372f3b7694fc3239bff6013d64ed9/nixos/overlay.nix
inputs: {
  nixpkgs.overlays = [
    (import ./noto-fonts-cjk-serif.nix)
    (import ./noto-fonts-cjk-sans.nix)
    (import ./noto-fonts.nix)
  ];
}