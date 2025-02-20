{ pkgs, ... }: {
  home.packages = with pkgs; [
    rustup
    cargo-deny # dependency license checker
    cargo-cache # cache management
    cargo-nextest # test runner
    cargo-workspaces # workspace management
    cargo-machete # unused dependencies detector
    cargo-features-manager # unused feature detector
    cargo-watch # auto-reload
    # cargo-vet # crate security checker TODO: https://github.com/NixOS/nixpkgs/pull/370510
    crate2nix
    rustowl
  ];
  # clang+mold could not resolve devEnv libraries defined in flake
  # home.file.".cargo/config.toml".text = ''
  #   		[target.x86_64-unknown-linux-gnu]
  #   		linker = "${pkgs.clang}/bin/clang"
  #   		rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
  #   		'';
}
