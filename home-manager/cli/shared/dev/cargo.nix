{pkgs, ...}: {
  home.packages = with pkgs; [
    rustup
    cargo-deny
    cargo-cache
    cargo-nextest
    cargo-workspaces
    crate2nix
  ];
}