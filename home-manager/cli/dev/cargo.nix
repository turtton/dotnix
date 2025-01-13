{ pkgs, ... }:
let
  cargo-features-manager = with pkgs; rustPlatform.buildRustPackage rec {
    pname = "cargo-features-manager";
    version = "0.6.0";
    src = fetchFromGitHub {
      owner = "ToBinio";
      repo = "cargo-features-manager";
      rev = "v${version}";
      hash = "sha256-34XYDeimYY4lx/IhjrFe8ZgrvnXb7+nSjyzIcOJZjLc=";
    };
    cargoHash = "sha256-Cf9n5whzwL1QzrNFIqOOz/JF+Uesn05JMbXDP0TZMCc=";
  };
in
{
  home.packages = with pkgs; [
    rustup
    cargo-deny # dependency license checker
    cargo-cache # cache management
    cargo-nextest # test runner
    cargo-workspaces # workspace management
    cargo-machete # unused dependencies detector
    cargo-features-manager # unused feature detector
    cargo-watch # auto-reload
    cargo-vet # crate security checker
    crate2nix
  ];
  # clang+mold could not resolve devEnv libraries defined in flake
  # home.file.".cargo/config.toml".text = ''
  #   		[target.x86_64-unknown-linux-gnu]
  #   		linker = "${pkgs.clang}/bin/clang"
  #   		rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
  #   		'';
}
