{pkgs, ...}: {
  home.packages = with pkgs; [
    # Replaced by rust-overlay(see flake.nix
    rust-bin.stable.latest.default
    cargo-deny
    cargo-cache
    cargo-nextest
    cargo-workspaces
    crate2nix
  ];
}