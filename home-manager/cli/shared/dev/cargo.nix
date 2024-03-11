{pkgs, ...}: {
  home.packages = with pkgs; [
    # Replaced by rust-overlay(see flake.nix
    (rust-bin.stable.latest.default.override {
      targets = ["wasm32-unknown-unknown" "wasm32-wasi"];
    })
    cargo-deny
    cargo-cache
    cargo-nextest
    cargo-workspace
    crate2nix
  ];
}